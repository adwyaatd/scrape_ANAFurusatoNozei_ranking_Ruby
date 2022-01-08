FROM lambci/lambda:build-ruby2.5
WORKDIR /var/task
RUN yum -y install mysql-devel
RUN gem update bundler
# RUN apt-get update -qq && apt-get install -y build-essential node.js
# RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
        # && apt-get install -y nodejs

# RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
#   && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
#   && apt-get update -qq \
#   && apt-get install -y nodejs yarn postgresql-client

# 署名を追加(chromeのインストールに必要) -> apt-getでchromeと依存ライブラリをインストール
# RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add \
#   && echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | tee /etc/apt/sources.list.d/google-chrome.list \
#   && apt-get update -qq \
#   && apt-get install -y google-chrome-stable libnss3 libgconf-2-4

# # chromeの追加
# RUN CHROME_DRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` && \
#     wget -N http://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip -P ~/ && \
#     unzip ~/chromedriver_linux64.zip -d ~/ && \
#     rm ~/chromedriver_linux64.zip && \
#     chown root:root ~/chromedriver && \
#     chmod 755 ~/chromedriver && \
#     mv ~/chromedriver /usr/local/bin/
CMD "/bin/bash"