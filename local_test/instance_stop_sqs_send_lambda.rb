require "aws-sdk-sqs"

queue_name = "stop_instance_queue"
msg_b = "stop time:#{DateTime.now.strftime("%Y年%-m月%-d日 %-H時%-M分%-S秒")}"

sqs = Aws::SQS::Client.new(region: 'ap-northeast-1')

begin
  queue_url = sqs.get_queue_url(queue_name: queue_name).queue_url
  pp "queue_url:#{queue_url}"
  pp "msg_b:#{msg_b}"

  send_message_result = sqs.send_message({
    queue_url: queue_url,
    message_body: msg_b
    # message_group_id: "message_group_id-#{Date.today}+#{Time.now.to_i}",
    # message_deduplication_id: "message_deduplication_id-#{Date.today}+#{Time.now.to_i}",
    # message_attributes: {
    #   "Title" => {
    #     string_value: "The Whistler",
    #     data_type: "String"
    #   },
    #   "Author" => {
    #     string_value: "John Grisham",
    #     data_type: "String"
    #   },
    #   "WeeksOn" => {
    #     string_value: "6",
    #     data_type: "Number"
    #   }
    # }
  })
rescue => e
  pp e
end

puts send_message_result.message_id

pp "receive_message-----------------------------------"

receive_message_result = sqs.receive_message({
  queue_url: queue_url,
  message_attribute_names: ["All"], # Receive all custom attributes.
  max_number_of_messages: 10, # Receive at most one message.
  wait_time_seconds: 0 # Do not wait to check for the message.
})

pp "receive_message_result:#{receive_message_result}"

# Display information about the message.
# Display the message's body and each custom attribute value.
receive_message_result.messages.each_with_index do |message,i|
  pp "No. #{i+1}"
  puts "message.body: #{message.body}"
  begin
    puts "message_id: #{message.message_id}"
    # puts "message_deduplication_id: #{message.message_deduplication_id}"
    # puts "Title: #{message.message_attributes["Title"]["string_value"]}"
    # puts "Author: #{message.message_attributes["Author"]["string_value"]}"
    # puts "WeeksOn: #{message.message_attributes["WeeksOn"]["string_value"]}"
  rescue => e
  pp e
  end

  pp "Delete the message from the queue."
  sqs.delete_message({
    queue_url: queue_url,
    receipt_handle: message.receipt_handle
  })
  pp "-----------------------------------------------"
end

pp "end"
return