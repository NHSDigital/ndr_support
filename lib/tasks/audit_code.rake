SAFETY_FILE =
  if defined?(Rails)
    Rails.root.join('config', 'code_safety.yml')
  else
    'code_safety.yml'
  end

# Temporary overrides to only audit external access files
SAFETY_REPOS = [['/svn/era', '/svn/extra/era/external-access']]

require 'yaml'

# Parameter max_print is number of entries to print before truncating output
# (negative value => print all)
def audit_code_safety(max_print = 20, ignore_new = false, show_diffs = false, show_in_priority = false, user_name = 'usr')
  puts 'Running source code safety audit script.'
  puts

  max_print = 1_000_000 if max_print < 0
  safety_cfg = File.exist?(SAFETY_FILE) ? YAML.load_file(SAFETY_FILE) : {}
  file_safety = safety_cfg['file safety']
  if file_safety.nil?
    puts "Creating new 'file safety' block in #{SAFETY_FILE}"
    safety_cfg['file safety'] = file_safety = {}
  end
  file_safety.each do |_k, v|
    rev = v['safe_revision']
    v['safe_revision'] = rev.to_s if rev.is_a?(Integer)
  end
  orig_count = file_safety.size

  safety_repo = trunk_repo = get_trunk_repo

  # TODO: below is broken for git-svn
  # Is it needed?

  SAFETY_REPOS.each do |suffix, alt|
    # Temporarily override to only audit a different file list
    if safety_repo.end_with?(suffix)
      safety_repo = safety_repo[0...-suffix.length] + alt
      break
    end
  end

  if ignore_new
    puts "Not checking for new files in #{safety_repo}"
  else
    puts "Checking for new files in #{safety_repo}"
    new_files = get_new_files(safety_repo)
    # Ignore subdirectories, and exclude code_safety.yml by default.
    new_files.delete_if { |f| f =~ /[\/\\]$/ || f == SAFETY_FILE }
    new_files.each do |f|
      next if file_safety.key?(f)
      file_safety[f] = {
        'comments' => nil,
        'reviewed_by' => nil,
        'safe_revision' => nil }
    end
    File.open(SAFETY_FILE, 'w') do |file|
      # Consistent file diffs, as ruby preserves Hash insertion order since v1.9
      safety_cfg['file safety'] = Hash[file_safety.sort]
      YAML.dump(safety_cfg, file) # Save changes before checking latest revisions
    end
  end
  puts "Updating latest revisions for #{file_safety.size} files"
  set_last_changed_revision(trunk_repo, file_safety, file_safety.keys)
  puts "\nSummary:"
  puts "Number of files originally in #{SAFETY_FILE}: #{orig_count}"
  puts "Number of new files added: #{file_safety.size - orig_count}"

  # Now generate statistics:
  unknown = file_safety.values.select { |x| x['safe_revision'].nil? }
  unsafe = file_safety.values.select do |x|
    !x['safe_revision'].nil? && x['safe_revision'] != -1 &&
    x['last_changed_rev'] != x['safe_revision'] &&
    !(x['last_changed_rev'] =~ /^[0-9]+$/ && x['safe_revision'] =~ /^[0-9]+$/ &&
      x['last_changed_rev'].to_i < x['safe_revision'].to_i)
  end
  puts "Number of files with no safe version: #{unknown.size}"
  puts "Number of files which are no longer safe: #{unsafe.size}"
  puts
  printed = []
  # We also print a third category: ones which are no longer in the repository
  file_list =
    if show_in_priority
      file_safety.sort_by { |_k, v| v.nil? ? -100 : v['last_changed_rev'].to_i }.map(&:first)
    else
      file_safety.keys.sort
    end

  file_list.each do |f|
    if print_file_safety(file_safety, trunk_repo, f, false, printed.size >= max_print)
      printed << f
    end
  end
  puts "... and #{printed.size - max_print} others" if printed.size > max_print
  if show_diffs
    puts
    printed.each do |f|
      print_file_diffs(file_safety, trunk_repo, f, user_name)
    end
  end

  # Returns `true` unless there are pending reviews:
  unsafe.length.zero? && unknown.length.zero?
end

# Print summary details of a file's known safety
# If not verbose, only prints details for unsafe files
# Returns true if anything printed (or would have been printed if silent),
# or false otherwise.
def print_file_safety(file_safety, repo, fname, verbose = false, silent = false)
  msg = "#{fname}\n  "
  entry = file_safety[fname]
  msg += 'File not in audit list' if entry.nil?

  if entry['safe_revision'].nil?
    msg += 'No safe revision known'
    msg += ", last changed #{entry['last_changed_rev']}" unless entry['last_changed_rev'].nil?
  else
    repolatest = entry['last_changed_rev'] # May have been prepopulated en mass
    msg += 'Not in repository: ' if entry['last_changed_rev'] == -1
    if (repolatest != entry['safe_revision']) &&
       !(repolatest =~ /^[0-9]+$/ && entry['safe_revision'] =~ /^[0-9]+$/ &&
         repolatest.to_i < entry['safe_revision'].to_i)
      # (Allow later revisions to be treated as safe for svn)
      msg += "No longer safe since revision #{repolatest}: "
    else
      return false unless verbose
      msg += 'Safe: '
    end
    msg += "revision #{entry['safe_revision']} reviewed by #{entry['reviewed_by']}"
  end
  msg += "\n  Comments: #{entry['comments']}" if entry['comments']
  puts msg unless silent
  true
end

def flag_file_as_safe(release, reviewed_by, comments, f)
  safety_cfg = YAML.load_file(SAFETY_FILE)
  file_safety = safety_cfg['file safety']

  unless File.exist?(f)
    abort("Error: Unable to flag non-existent file as safe: #{f}")
  end
  unless file_safety.key?(f)
    file_safety[f] = {
      'comments' => nil,
      'reviewed_by' => :dummy, # dummy value, will be overwritten
      'safe_revision' => nil }
  end
  entry = file_safety[f]
  entry_orig = entry.dup
  if comments.to_s.length > 0 && entry['comments'] != comments
    entry['comments'] = if entry['comments'].to_s.empty?
                          comments
                        else
                          "#{entry['comments']}#{'.' unless entry['comments'].end_with?('.')} Revision #{release}: #{comments}"
                        end
  end
  if entry['safe_revision']
    unless release
      abort("Error: File already has safe revision #{entry['safe_revision']}: #{f}")
    end
    if release.is_a?(Integer) && release < entry['safe_revision']
      puts("Warning: Rolling back safe revision from #{entry['safe_revision']} to #{release} for #{f}")
    end
  end
  entry['safe_revision'] = release
  entry['reviewed_by'] = reviewed_by
  if entry == entry_orig
    puts "No changes when updating safe_revision to #{release || '[none]'} for #{f}"
  else
    File.open(SAFETY_FILE, 'w') do |file|
      # Consistent file diffs, as ruby preserves Hash insertion order since v1.9
      safety_cfg['file safety'] = Hash[file_safety.sort]
      YAML.dump(safety_cfg, file) # Save changes before checking latest revisions
    end
    puts "Updated safe_revision to #{release || '[none]'} for #{f}"
  end
end

# Determine the type of repository
def repository_type
  return 'svn' if Dir.exist?('.svn')
  return 'git-svn' if Dir.exist?('.git') && open('.git/config').grep(/svn/).any?
  return 'git' if Dir.exist?('.git') && open('.git/config').grep(/git/).any?
  'not known'
end

def get_trunk_repo
  case repository_type
  when 'svn'
    repo_info = %x[svn info]
    puts 'svn case'
    return repo_info.split("\n").select { |x| x =~ /^URL: / }.collect { |x| x[5..-1] }.first
  when 'git-svn'
    puts 'git-svn case'
    repo_info = %x[git svn info]
    return repo_info.split("\n").select { |x| x =~ /^URL: / }.collect { |x| x[5..-1] }.first
  when 'git'
    puts 'git case'
    repo_info = %x[git remote -v]
    return repo_info.split("\n").first[7..-9]
  else
    return 'Information not available. Unknown repository type'
  end
end

def get_new_files(safety_repo)
  case repository_type
  when 'svn', 'git-svn'
    %x[svn ls -R "#{safety_repo}"].split("\n")
  when 'git'
    #%x[git ls-files --modified].split("\n")
    %x[git ls-files].split("\n")

    # TODO: Below is for remote repository - for testing use local files
    #new_files = %x[git ls-files --modified #{safety_repo}].split("\n")
    # TODO: Do we need the --modified option?
    #new_files = %x[git ls-files --modified].split("\n")
  else
    []
  end
end

# Fill in the latest changed revisions in a file safety map.
# (Don't write this data to the YAML file, as it is intrinsic to the SVN
# repository.)
def set_last_changed_revision(repo, file_safety, fnames)
  dot_freq = (file_safety.size / 40.0).ceil # Print up to 40 progress dots
  case repository_type
  when 'git'
    fnames = file_safety.keys if fnames.nil?

    fnames.each_with_index do |f, i|
      info = %x[git log -n 1 #{f}].split("\n").first[7..-1]
      if info.nil? || info.empty?
        file_safety[f]['last_changed_rev'] = -1
      else
        file_safety[f]['last_changed_rev'] = info
      end
      # Show progress
      print '.' if (i % dot_freq) == 0
    end
    puts
  when 'git-svn', 'svn'
    fnames = file_safety.keys if fnames.nil?

    fnames.each_with_index do |f, i|
      last_revision = get_last_changed_revision(repo, f)
      if last_revision.nil? || last_revision.empty?
        file_safety[f]['last_changed_rev'] = -1
      else
        file_safety[f]['last_changed_rev'] = last_revision
      end
      # Show progress
      print '.' if (i % dot_freq) == 0
    end
    puts
    # NOTE: Do we need the following for retries?
#     if retries && result.size != fnames.size && fnames.size > 1
#        # At least one invalid (deleted file --> subsequent arguments ignored)
#        # Try each file individually
#        # (It would probably be safe to continue from the extra_info.size argument)
#        puts "Retrying (got #{result.size}, expected #{fnames.size})" if debug >= 2
#        result = []
#        fnames.each{ |f|
#           result += svn_info_entries([f], repo, false, debug)
#        }
#      end
  end
end

# Return the last changed revision
def get_last_changed_revision(repo, fname)
  case repository_type
  when 'git'
    %x[git log -n 1 "#{fname}"].split("\n").first[7..-1]
  when 'git-svn', 'svn'
    begin
      svn_info = %x[svn info -r head "#{repo}/#{fname}"]
    rescue
      puts 'we have an error in the svn info line'
    end
    begin
      svn_info.match('Last Changed Rev: ([0-9]*)').to_a[1]
    rescue
      puts 'We have an error in getting the revision'
    end
  end
end

# Get mime type. Note that Git does not have this information
def get_mime_type(repo, fname)
  case repository_type
  when 'git'
    'Git does not provide mime types'
  when 'git-svn', 'svn'
    %x[svn propget svn:mime-type "#{repo}/#{fname}"].chomp
  end
end

# # Print file diffs, for code review
def print_file_diffs(file_safety, repo, fname, user_name)
  entry = file_safety[fname]
  repolatest = entry['last_changed_rev']
  safe_revision = entry['safe_revision']

  if safe_revision.nil?
    first_revision = set_safe_revision
    print_repo_file_diffs(repolatest, repo, fname, user_name, first_revision)
  else

    rev = get_last_changed_revision(repo, fname)
    if rev
      mime = get_mime_type(repo, fname)
    end

    print_repo_file_diffs(repolatest, repo, fname, user_name, safe_revision) if repolatest != safe_revision
  end
end

# Returns first commit for git and 0 for svn in order to be used to display
# new files. Called from print_file_diffs
def set_safe_revision
  case repository_type
  when 'git'
    %x[git rev-list --max-parents=0 HEAD].chomp
  when 'git-svn', 'svn'
    0
  end
end

def print_repo_file_diffs(repolatest, repo, fname, user_name, safe_revision)
  case repository_type
  when 'git'
    puts %[git --no-pager diff -b #{safe_revision}..#{repolatest} #{fname}]
    puts %x[git --no-pager diff -b #{safe_revision}..#{repolatest} #{fname}]
  when 'git-svn', 'svn'
    puts %[svn diff -r #{safe_revision.to_i}:#{repolatest.to_i} -x -b #{repo}/#{fname}]
    puts %x[svn diff -r #{safe_revision.to_i}:#{repolatest.to_i} -x -b #{repo}/#{fname}]
  else
    puts 'Unknown repo'
  end

  puts %(To flag the changes to this file as safe, run:)
  puts %(  rake audit:safe release=#{repolatest} file=#{fname} reviewed_by=#{user_name} comments="")
  puts
end

def release_valid?
  case repository_type
  when 'svn', 'git-svn'
    ENV['release'] =~ /\A[0-9][0-9]*\Z/
  when 'git'
    ENV['release'] =~ /\A[0-9a-f]{40}\Z/
  else
    false
  end
end

def get_release
  release = ENV['release']
  release = nil if release == '0'
  case repository_type
  when 'svn', 'git-svn'
    release.to_i
  when 'git'
    release
  else
    ''
  end
  release
end

namespace :audit do
  desc "Audit safety of source code.
Usage: audit:code [max_print=n] [ignore_new=false|true] [show_diffs=false|true] [reviewed_by=usr]

File #{SAFETY_FILE} lists the safety and revision information
of the era source code. This task updates the list, and [TODO] warns about
files which have changed since they were last verified as safe."
  task(:code) do
    puts 'Usage: audit:code [max_print=n] [ignore_new=false|true] [show_diffs=false|true] [show_in_priority=false|true] [reviewed_by=usr]'
    puts "This is a #{repository_type} repository"

    ignore_new = (ENV['ignore_new'].to_s =~ /\Atrue\Z/i)
    show_diffs = (ENV['show_diffs'].to_s =~ /\Atrue\Z/i)
    show_in_priority = (ENV['show_in_priority'].to_s =~ /\Atrue\Z/i)
    max_print = ENV['max_print'] =~ /\A-?[0-9][0-9]*\Z/ ? ENV['max_print'].to_i : 20
    reviewer  = ENV['reviewed_by']

    all_safe = audit_code_safety(max_print, ignore_new, show_diffs, show_in_priority, reviewer)

    unless show_diffs
      puts 'To show file diffs, run:  rake audit:code max_print=-1 show_diffs=true'
    end

    exit(1) unless all_safe
  end

  desc "Flag a source file as safe.

Usage:
  Flag as safe:   rake audit:safe release=revision reviewed_by=usr [comments=...] file=f
  Needs review:   rake audit:safe release=0 [comments=...] file=f"
  task(:safe) do
    required_fields = %w(release file)
    required_fields << 'reviewed_by' unless ENV['release'] == '0'
    missing = required_fields.collect { |f| (f if ENV[f].to_s.empty? || (f == 'reviewed_by' && ENV[f] == 'usr')) }.compact # Avoid accidental missing username
    unless missing.empty?
      puts 'Usage: rake audit:safe release=revision reviewed_by=usr [comments=...] file=f'
      puts 'or, to flag a file for review: rake audit:safe release=0 [comments=...] file=f'
      abort("Error: Missing required argument(s): #{missing.join(', ')}")
    end

    unless release_valid?
      puts 'Usage: rake audit:safe release=revision reviewed_by=usr [comments=...] file=f'
      puts 'or, to flag a file for review: rake audit:safe release=0 [comments=...] file=f'
      abort("Error: Invalid release: #{ENV['release']}")
    end

    release = get_release
    flag_file_as_safe(release, ENV['reviewed_by'], ENV['comments'], ENV['file'])
  end

  desc 'Wraps audit:code, and stops if any review is pending/stale.'
  task(:ensure_safe) do
    begin
      puts 'Checking code safety...'

      begin
        $stdout = $stderr = StringIO.new
        Rake::Task['audit:code'].invoke
      ensure
        $stdout, $stderr = STDOUT, STDERR
      end
    rescue SystemExit => ex
      puts '=============================================================='
      puts 'Code safety review of some files are not up-to-date; aborting!'
      puts '  - to review the files in question, run:  rake audit:code'
      puts '=============================================================='

      raise ex
    end
  end
end

# Prevent building of un-reviewed gems:
task :build => :'audit:ensure_safe'
