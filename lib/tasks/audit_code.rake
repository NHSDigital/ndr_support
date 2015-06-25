SAFETY_FILE =
  if defined?(Rails)
    Rails.root.join('config', 'code_safety.yml')
  else
    'code_safety.yml'
  end

# Temporarily override to only audit external access files
SAFETY_REPO = "https://deepthought/svn/extra/era/external-access"

require 'yaml'

# Force yaml output from hashes to be ordered
# e.g. so that file diffs are consistent
# TODO: Instead declare ordered version of YAML.dump or use OrderedHash
def order_to_yaml_output!
  if RUBY_VERSION =~ /\A1\.9/
    puts "Warning: Hash output will not be sorted." unless YAML::ENGINE.syck?
    eval <<-EOT
    class Hash
      # Replacing the to_yaml function so it'll serialize hashes sorted (by their keys)
      # See http://snippets.dzone.com/posts/show/5811
      #
      # Original function is in /usr/lib/ruby/1.9.1/syck/rubytypes.rb
      def to_yaml( opts = {} )
        return super unless YAML::ENGINE.syck?
        YAML::quick_emit( self, opts ) do |out|
          out.map( taguri, to_yaml_style ) do |map|
            sort.each do |k, v|   # <-- here's my addition (the 'sort')
            #each do |k, v|
              map.add( k, v )
            end
          end
        end
      end
    end
    EOT
  end
end

# Run a PL/SQL based password cracker on the main database to identify weak
# passwords.
# Parameter max_print is number of entries to print before truncating output
# (negative value => print all)
def audit_code_safety(max_print = 20, ignore_new = false, show_diffs = false, show_in_priority = false, user_name = 'usr')
  puts <<EOT
Running source code safety audit script.
This currently takes about 3 minutes to run.
We seem to have issues with Apache on deepthought rate limiting svn requests.

EOT
  max_print = 1000000 if max_print < 0
  safety_cfg = YAML.load_file(SAFETY_FILE)
  file_safety = safety_cfg["file safety"]
  if file_safety.nil?
    safety_cfg["file safety"] = file_safety = {}
  end
  orig_count = file_safety.size

  if defined? SAFETY_REPO
    # Temporarily override to only audit a different file list
    repo = SAFETY_REPO
  else
    repo = %x[svn info].split("\n").select{|x| x =~ /^URL: /}.collect{|x| x[5..-1]}.first
  end
  if ignore_new
    puts "Not checking for new files in #{repo}"
  else
    puts "Checking for new files in #{repo}"
    new_files = %x[svn ls -R "#{repo}"].split("\n")
    # Ignore subdirectories
    new_files.delete_if{|f| f =~ /[\/\\]$/}
    new_files.each{|f|
      unless file_safety.has_key?(f)
        file_safety[f] = {
          "comments" => nil,
          "reviewed_by" => nil,
          "safe_revision" => nil }
      end
    }
    File.open(SAFETY_FILE, 'w') do |file|
      order_to_yaml_output!
      YAML.dump(safety_cfg, file) # Save changes before checking latest revisions
    end
  end
  puts "Checking latest revisions"
  update_changed_rev(file_safety)
  puts "\nSummary:"
  puts "Number of files originally in #{SAFETY_FILE}: #{orig_count}"
  puts "Number of new files added: #{file_safety.size - orig_count}"

  # Now generate statistics:
  unknown = file_safety.values.select{|x| x["safe_revision"].nil?}
  unsafe = file_safety.values.select{|x|
    !x["safe_revision"].nil? && x["safe_revision"] != -1 &&
    x["last_changed_rev"] > x['safe_revision']
  }
  puts "Number of files with no safe version: #{unknown.size}"
  puts "Number of files which are no longer safe: #{unsafe.size}"
  puts
  printed = []
  # We also print a third category: ones which are no longer in the repository
  if show_in_priority
    file_list = file_safety.sort_by {|k,v| v.nil? ? -100 : v["last_changed_rev"].to_i}.map(&:first)
  else
    file_list = file_safety.keys.sort
  end
  
  file_list.each{|f|
    if print_file_safety(file_safety, f, false, printed.size >= max_print)
      printed << f
    end
  }
  puts "... and #{printed.size - max_print} others" if printed.size > max_print
  if show_diffs
    puts
    printed.each{|f|
      print_file_diffs(file_safety, f, user_name)
    }
  end
end

# Print summary details of a file's known safety
# If not verbose, only prints details for unsafe files
# Returns true if anything printed (or would have been printed if silent),
# or false otherwise.
def print_file_safety(file_safety, fname, verbose = false, silent = false)
  msg = "#{fname}\n  "
  entry = file_safety[fname]
  if entry.nil?
    msg += "File not in audit list"
  elsif entry["safe_revision"].nil?
    msg += "No safe revision known"
    msg += ", last changed at revision #{entry['last_changed_rev']}" unless entry["last_changed_rev"].nil?
  else
    if entry["last_changed_rev"].nil?
      update_changed_rev(file_safety, [fname])
    end
    svnlatest = entry["last_changed_rev"] # May have been prepopulated en mass
    if entry["last_changed_rev"] == -1
      msg += "Not in svn repository: "
    elsif svnlatest > entry['safe_revision']
      msg += "No longer safe since revision #{svnlatest}: "
    else
      return false unless verbose
      msg += "Safe: "
    end
    msg += "revision #{entry['safe_revision']} reviewed by #{entry['reviewed_by']}"
  end
  msg += "\n  Comments: #{entry['comments']}" if entry['comments']
  puts msg unless silent
  return true
end

# Print file diffs, for code review
def print_file_diffs(file_safety, fname, user_name)
  entry = file_safety[fname]
  if entry.nil?
    # File not in audit list
  elsif entry["safe_revision"].nil?
    puts "No safe revision for #{fname}"
    rev = %x[svn info -r head "#{fname}"].match('Last Changed Rev: ([0-9]*)').to_a[1]
    if rev
      mime_type = %x[svn propget svn:mime-type "#{fname}"].chomp
      if ['application/octet-stream'].include?(mime_type)
        puts "Cannot display: file marked as a binary type."
        puts "svn:mime-type = #{mime_type}"
      else
        fdata = %x[svn cat -r "#{rev}" "#{fname}"]
        # TODO: Add header information like svn
        puts fdata.split("\n").collect{|line| "+ #{line}"}
      end
      puts "To flag the changes to this file as safe, run:"
    else
      puts "Please code review a recent working copy, note the revision number, and run:"
      rev = '[revision]'
    end
    puts %(  rake audit:safe release=#{rev} file=#{fname} reviewed_by=#{user_name} comments="")
    puts
  else
    if entry["last_changed_rev"].nil?
      update_changed_rev(file_safety, [fname])
    end
    svnlatest = entry["last_changed_rev"] # May have been prepopulated en mass
    if entry["last_changed_rev"] == -1
      # Not in svn repository
    elsif svnlatest > entry['safe_revision']
      cmd = "svn diff -r #{entry['safe_revision']}:#{svnlatest} -x-b #{fname}"
      puts cmd
      system(cmd)
      puts %(To flag the changes to this file as safe, run:)
      puts %(  rake audit:safe release=#{svnlatest} file=#{fname} reviewed_by=#{user_name} comments="")
      puts
    else
      # Safe
    end
  end
end

# Fill in the latest changed revisions in a file safety map.
# (Don't write this data to the YAML file, as it is intrinsic to the SVN
# repository.)
def update_changed_rev(file_safety, fnames = nil)
  fnames = file_safety.keys if fnames.nil?
  # TODO: Use svn info --xml instead
  # TODO: Is it possible to get %x[] syntax to accept variable arguments?
  #all_info = %x[svn info -r HEAD "#{fnames.join(' ')}"]
  repo = %x[svn info].split("\n").select{|x| x =~ /^URL: /}.collect{|x| x[5..-1]}.first
  # Filename becomes too long, and extra arguments get ignored
  #all_info = Kernel.send("`", "svn info -r HEAD #{fnames.sort.join(' ')}").split("\n\n")
  # Note: I'd like to be able to use svn -u status -v instead of svn info,
  #       but it seems to refer only to the local working copy...
  f2 = fnames.sort # Sorted copy is safe to change
  all_info = []
  while f2 && !f2.empty?
    blocksize = 10
    extra_info = svn_info_entries(f2.first(blocksize))
    #if extra_info.size != [blocksize, f2.size].min
    #  puts "Mismatch (got #{extra_info.size}, expected #{[blocksize, f2.size].min})"
    #end
    all_info += extra_info
    f2 = f2[blocksize..-1]
  end
  fnames.each{|f|
    #puts "Checking for URL: #{repo}/#{f}"
    #puts all_info[0].inspect
    info = all_info.find{|x| x.include?("URL: #{repo}/#{f}")}
    if info
      info = info.split("\n")
    else
      #puts "Unknown: #{f}"
    end
    #info = %x[svn info -r HEAD "#{f}"].split("\n")
    if info.nil? || info.empty?
      # svn writes to stderr: "svn: '#{f}' has no URL", or
      # "#{f}:  (Not a versioned resource)"
      file_safety[f]["last_changed_rev"] = -1 # Flag as non-existent
    else
      file_safety[f]["last_changed_rev"] = info.
        select{|x| x =~ /^Last Changed Rev: /}.collect{|x| x[18..-1]}[0].to_i
    end
  }
end

# Returns a list of svn info entries, given a list of filenames.
# Automatically retries (by default) if multiple filenames are given, and fewer
# entries are returned than expected.
# debug argument: 0 => silent (even for errors), 1 => only print errors,
#                 2 => print commands + errors
def svn_info_entries(fnames, retries = true, debug = 0)
  puts "svn info -r HEAD #{fnames.join(' ')}" if debug >= 2
  return [] if fnames.empty?
  # Silence if retries and debug=1, as we'll get repeats when we retry
  silencer = (debug == 2 || (debug == 1 && !retries)) ? "" :
    (RUBY_PLATFORM =~ /mswin32|mingw32/ ? " 2>nul " : " 2>/dev/null ")
  result = Kernel.send("`", "svn info -r HEAD #{fnames.join(' ')}#{silencer}").split("\n\n")
  if retries && result.size != fnames.size && fnames.size > 1
    # At least one invalid (deleted file --> subsequent arguments ignored)
    # Try each file individually
    # (It would probably be safe to continue from the extra_info.size argument)
    puts "Retrying (got #{result.size}, expected #{fnames.size})" if debug >= 2
    result = []
    fnames.each{ |f|
      result += svn_info_entries([f], false, debug)
    }
  end
  result
end

def flag_file_as_safe(release, reviewed_by, comments, f)
  safety_cfg = YAML.load_file(SAFETY_FILE)
  file_safety = safety_cfg["file safety"]

  unless File.exist?(f)
    abort("Error: Unable to flag non-existent file as safe: #{f}")
  end
  unless file_safety.has_key?(f)
    file_safety[f] = {
      "comments" => nil,
      "reviewed_by" => :dummy, # dummy value, will be overwritten
      "safe_revision" => nil }
  end
  entry = file_safety[f]
  entry_orig = entry.dup
  if comments.present? && entry["comments"] != comments
    entry["comments"] = if entry["comments"].blank?
                          comments
                        else
                          "#{entry["comments"]}#{'.' unless entry["comments"].end_with?('.')} Revision #{release}: #{comments}"
                        end
  end
  if entry["safe_revision"]
    unless release
      abort("Error: File already has safe revision #{entry["safe_revision"]}: #{f}")
    end
    if release < entry["safe_revision"]
      puts("Warning: Rolling back safe revision from #{entry['safe_revision']} to #{release} for #{f}")
    end
  end
  entry["safe_revision"] = release
  entry["reviewed_by"] = reviewed_by
  if entry == entry_orig
    puts "No changes when updating safe_revision to #{release || '[none]'} for #{f}"
  else
    File.open(SAFETY_FILE, 'w') do |file|
      order_to_yaml_output!
      YAML.dump(safety_cfg, file) # Save changes before checking latest revisions
    end
    puts "Updated safe_revision to #{release || '[none]'} for #{f}"
  end
end



namespace :audit do
  
  desc "Audit safety of source code.
Usage: audit:code [max_print=n] [ignore_new=false|true] [show_diffs=false|true] [reviewed_by=usr]

File #{SAFETY_FILE} lists the safety and revision information
of the era source code. This task updates the list, and [TODO] warns about
files which have changed since they were last verified as safe."
  task(:code) do
    puts "Usage: audit:code [max_print=n] [ignore_new=false|true] [show_diffs=false|true] [show_in_priority=false|true] [reviewed_by=usr]"
    ignore_new = (ENV['ignore_new'].to_s =~ /\Atrue\Z/i)
    show_diffs = (ENV['show_diffs'].to_s =~ /\Atrue\Z/i)
    show_in_priority = (ENV['show_in_priority'].to_s =~ /\Atrue\Z/i)
    if ENV['max_print'] =~ /\A-?[0-9][0-9]*\Z/
      audit_code_safety(ENV['max_print'].to_i, ignore_new, show_diffs, show_in_priority, ENV['reviewed_by'])
    else
      audit_code_safety(20, ignore_new, show_diffs, show_in_priority, ENV['reviewed_by'])
    end
    unless show_diffs
      puts "To show file diffs, run:  rake audit:code max_print=-1 show_diffs=true"
    end
  end

  desc "Flag a source file as safe.

Usage:
  Flag as safe:   rake audit:safe release=revision reviewed_by=usr [comments=...] file=f
  Needs review:   rake audit:safe release=0 [comments=...] file=f"
  task (:safe) do
    required_fields = ["release", "file"]
    required_fields << "reviewed_by" unless ENV['release'] == '0'
    missing = required_fields.collect{|f| (f if ENV[f].blank? || (f=='reviewed_by' && ENV[f] == 'usr'))}.compact # Avoid accidental missing username
    if !missing.empty?
      puts "Usage: rake audit:safe release=revision reviewed_by=usr [comments=...] file=f"
      puts "or, to flag a file for review: rake audit:safe release=0 [comments=...] file=f"
      abort("Error: Missing required argument(s): #{missing.join(', ')}")
    end
    unless ENV['release'] =~ /\A[0-9][0-9]*\Z/
      puts "Usage: rake audit:safe release=revision reviewed_by=usr [comments=...] file=f"
      puts "or, to flag a file for review: rake audit:safe release=0 [comments=...] file=f"
      abort("Error: Invalid release: #{ENV['release']}")
    end
    release = ENV['release'].to_i
    release = nil if release == 0
    flag_file_as_safe(release, ENV['reviewed_by'], ENV['comments'], ENV['file'])
  end

end
