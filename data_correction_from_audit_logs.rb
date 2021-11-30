# ruby ../scripts/data_correction_from_audit_logs.rb /path_to.csv last_name,professional_license_number,controlled_substance_id
require 'csv'
require 'pry-byebug'
require 'rails'

audit_log_path = ARGV[0]
fields = ARGV[1].split(',')

def extract_val_for(field:, frm_raw_log:, type:)
  old_val_log = frm_raw_log[/<#{type.upcase}>(.*?)<\/#{type.upcase}>/m, 1]
  beg_marker = "<COLUMN name=\"#{field}\">"
  end_marker = "</COLUMN>"
  old_val_log[/#{beg_marker}(.*?)#{end_marker}/m, 1]
end

filtered_csv = CSV.generate do |csv|
  csv << ['User ID', 'Field', 'Original Val', 'Updated Val']

  CSV.parse(IO.read(audit_log_path), headers: true).each do |data|
    next if data['operation'].downcase != 'update'

    fields.each do |field_name|
      user_id = data.to_a.first.last.to_i,

      old_val = extract_val_for(field: field_name, frm_raw_log: data['xml_audit'], type: 'old')
      new_val = extract_val_for(field: field_name, frm_raw_log: data['xml_audit'], type: 'new')

      next if old_val.present? && !old_val.match("\\W")

      next if old_val == new_val

      puts "#{[ field_name, old_val, new_val]}"
      csv << [ field_name, old_val, new_val]
    end
  end
end

new_csv_path = audit_log_path.split('.csv').first + '-filtered.csv'
File.open(new_csv_path, 'w') { |f| f.write(filtered_csv) }