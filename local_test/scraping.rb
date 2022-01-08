require "google_drive"
require "googleauth"
require	"selenium-webdriver"

def setup_driver
  # service = Selenium::WebDriver::Service.chrome(path: '/opt/bin/chromedriver')
  # service = Selenium::WebDriver::Service.chrome(path: './bin/chromedriver')

  # client = Selenium::WebDriver::Remote::Http::Default.new
  # client.read_timeout = 20 # seconds

  # Selenium::WebDriver.for :chrome, service: service, options: driver_options
  Selenium::WebDriver.for :chrome, options: driver_options
end

def driver_options
  # options = Selenium::WebDriver::Chrome::Options.new(binary: '/opt/bin/headless-chromium')
  # options = Selenium::WebDriver::Chrome::Options.new(binary: './bin/headless-chromium')
  options = Selenium::WebDriver::Chrome::Options.new
  arguments = ["--headless", "--disable-gpu", "--window-size=1280x1696", "--disable-application-cache", "--disable-infobars", "--no-sandbox", "--hide-scrollbars", "--enable-logging", "--log-level=0", "--single-process", "--ignore-certificate-errors" "--homedir=/tmp"]
  arguments.each do |argument|
    options.add_argument(argument)
  end
  options
end

def get_session
  pp "セッション開始"
  credentials = Google::Auth::UserRefreshCredentials.new(
    client_id: "1020131189820-qpkqecfpalhcunv6q27619kdlm0sknrk.apps.googleusercontent.com",
    client_secret: "5z63V5xd5fwBNPcoqv4s4Bna",
    scope: [
      "https://www.googleapis.com/auth/drive",
      "https://spreadsheets.google.com/feeds/"
    ],
    refresh_token: "1//0edw4khTfQ532CgYIARAAGA4SNwF-L9IrwnThPxdOJKcylIZGXlIg1EJg78_Cczdo7RQ5uHQG-RW2SAXWeogtgCp-ETnbWbLWyEA"
  )
  # session = GoogleDrive::Session.from_config("config.json")
  GoogleDrive::Session.from_credentials(credentials)
end

# def lambda_handler(event:, context:)
  pp "処理開始"
  retry_cnt = 0

  datas = []
  begin
    begin
      d = setup_driver
      # wait = Selenium::WebDriver::Wait.new(binary: '/opt/bin/headless-chromium',timeout: 5)
      # wait = Selenium::WebDriver::Wait.new(binary: './bin/headless-chromium',timeout: 5)
      wait = Selenium::WebDriver::Wait.new(timeout: 5)

      pp "ANAサイトへ"
      d.navigate.to 'https://furusato.ana.co.jp/products/ranking.php'
    rescue => e
      pp e
      sleep(1)
      retry_cnt += 1
      retry if retry_cnt <= 2
    end

    # ランキング順位の取得
    pp "アイテムの数を取得"
    items = d.find_elements(:xpath,"//*[@id=\"ranking_weekly\"]/ul/li")
    items_count = items.count
    pp items_count

    # 繰り返し処理で、アイテムを1つずつ取得
    n = 1 #1から始める
    while n <= items_count
      pp "ランキング：#{n}位"
      begin
        item_element = d.find_element(:id ,"ranking_weekly_#{n}")
      rescue
        # 同率順位があって、アイテム数＞ランキング順位数の場合はスキップ
        pp "ランキングなし"
        next
      else
        ranking = n
        gift_area = d.find_element(:xpath, "//*[@id=\"ranking_weekly_#{n}\"]/a/section/h3/span[1]") # 北海道紋別市
        gift_area = gift_area.text
        pp gift_area
        gift_name = d.find_element(:xpath, "//*[@id=\"ranking_weekly_#{n}\"]/a/section/h3/span[2]") #10-68 オホーツク産ホタテ玉冷大(1kg)
        gift_name = gift_name.text
        pp gift_name
        gift_price = d.find_element(:xpath, "//*[@id=\"ranking_weekly_#{n}\"]/a/section/span[2]") # 10,000
        gift_price = gift_price.text
        pp gift_price

        gift_data = {ranking:ranking,gift_area:gift_area,gift_name:gift_name,gift_price:gift_price}
        datas.push(gift_data)
      end

      n += 1
    end

    d.quit
  rescue => e
    pp "スクレイピング失敗"
    pp e
    d.quit
    return
  else
    pp "スクレイピング成功"
    pp "スプレッドシートに書き込み開始"
    session = get_session
    key = '1Ww3kvLvsE9fEtcHIKfPl5hsTycvKEc2uRjM_oNxWtbI' #スプレッドシートの指定
    sheets = session.spreadsheet_by_key(key)
    sheet = sheets.worksheet_by_title("総合") #タブの指定

    pp "設定開始"
    last_row = sheet.num_rows #記載がある一番下の行数
    last_col = sheet.num_cols #記載がある一番右の列数
    today_col = last_col+1

    d = Date.today
    t = Time.now.strftime("%X")
    light_blue = Google::Apis::SheetsV4::Color.new(red: 0.850, green: 0.886, blue: 0.952) #16進数:D8E1F2 216:225:242
    light_red = Google::Apis::SheetsV4::Color.new(red: 0.968, green: 0.776, blue: 0.803) #16進数:F6C5CC 246:197:204
    light_yellow = Google::Apis::SheetsV4::Color.new(red: 0.996, green: 0.946, blue: 0.796) #16進数:FDF1CA 253:241:202
    black = GoogleDrive::Worksheet::Colors::BLACK

    # t:top b:bottom r:right l:left
    # s:solid w:double d:dotted
    ts_bs_border = {
      top: Google::Apis::SheetsV4::Border.new(
        style: "solid",
        color: black
      ),
      bottom: Google::Apis::SheetsV4::Border.new(
        style: "solid",
        color: black
      )
    }
    td_bd_rs_ls_border = {
      top: Google::Apis::SheetsV4::Border.new(
        style: "dotted",
        color: black
      ),
      bottom: Google::Apis::SheetsV4::Border.new(
        style: "dotted",
        color: black
      ),
      right: Google::Apis::SheetsV4::Border.new(
        style: "solid",
        color: black
      ),
      left: Google::Apis::SheetsV4::Border.new(
        style: "solid",
        color: black
      )
    }
    rw_border = {
      right: Google::Apis::SheetsV4::Border.new(
        style: "double",
        color: black
      )
    }
    pp "設定ここまで"

    # unless sheet[5,last_col] == d #1日1回指定の場合
    sheet[4,today_col] = t
    sheet[5,today_col] = d
    sheet[6,today_col] = %w(日 月 火 水 木 金 土)[d.wday]

    pp "今日の列の枠線設置"
    for i in 5 .. last_row # 今日の列に一番下の行まで枠線を設置
      sheet.update_borders(i,today_col,1,1,td_bd_rs_ls_border)
    end
    sheet.update_borders(5,today_col,2,1,ts_bs_border)

    # 返礼品の中に取得した品物の名前があるか照合
    datas.each do |d|
      last_row = sheet.num_rows #最下行を再定義
      new_row = last_row+1 #記載がある一番下+1個下の行数
      match_flag = false
      for r in 7 .. last_row
        # if sheet[r,2] == d[:gift_area] && sheet[r,3].include?(d[:gift_name]) && sheet[r,4].delete(",").to_i == d[:gift_price].delete(",").delete("円").to_i
        if sheet[r,3].include?(d[:gift_name])
          pp "返礼品名合致"
          if sheet[r,2] == d[:gift_area]
            pp "市区町村名合致"
            if sheet[r,4].delete(",").to_i == d[:gift_price].delete(",").delete("円").to_i
              pp "金額合致"
              sheet[r,today_col] = d[:ranking]
              # if sheet[r,last_col].to_i < d[:ranking].to_i #ランキングアップ
              #   sheet.set_background_color(r,today_col,1,1,light_blue)
              # elsif sheet[r,last_col].to_i > d[:ranking].to_i #ランキングダウン
              #   sheet.set_background_color(r,today_col,1,1,light_red)
              # else #ランキング変動なし
              #   sheet.set_background_color(r,today_col,1,1,light_yellow)
              # end
              match_flag = true
              break
            end
          end
        end
      end

      unless match_flag
        pp "合致なし。新規返礼品として登録"
        pp "gift_area:#{d[:gift_area]}"
        pp "gift_name:#{d[:gift_name]}"
        pp "gift_price:#{d[:gift_price]}"
        sheet[new_row,1] = sheet[last_row,1].to_i+1
        sheet[new_row,2] = d[:gift_area]
        sheet[new_row,3] = d[:gift_name]
        sheet[new_row,4] = d[:gift_price].delete(",").delete("円")
        sheet[new_row,today_col] = d[:ranking]
        pp "枠線設置"
        # 新規返礼品（下）の枠
        for i in 1..today_col
          sheet.update_borders(new_row,i,1,1,td_bd_rs_ls_border)
        end
        sheet.update_borders(new_row,1,1,1,rw_border)
      end
    end

    sheet.save
    pp "書き込み完了 全処理成功"
  end
# end