#
# Spec-file Name:: tomcat_spec.rb
#
#試験項目  :基本動作確認項目(Tomcat)
#環境定義書:環境定義書(Tomcat)
#
# Copyright(c) 2015 NTTDATA Corporation.
#
shared_examples 'tomcat_spec' do
  
#試験項目  :パラメタ設定 項目2 > 設定ファイルの確認
#環境定義書:JVM起動オプション
#ロジック番号:01
  describe file(property[:tomcat][:default_tomcat][:filepath]) do
    #キーバリュー形式のパラメータ設定の確認
    property[:tomcat][:default_tomcat][:key_eq_val].each do |key,value|
      its(:content) { should match "#{key}=#{value}" }
    end
    property[:tomcat][:default_tomcat][:key_val].each do |key,value|
      its(:content) { should match "#{key}#{value}" }
    end
  end

#試験項目  :パラメタ設定 項目2 > 設定ファイルの確認
#環境定義書:基本設定(server.xml)
#ロジック番号:02と03
  describe file(property[:tomcat][:server_xml][:filepath]) do
    #xmlタグ内のパラメータ設定の確認
    property[:tomcat][:server_xml][:key_val].each do |key,value|
      #設定値がネストされているxmlタグの設定値の確認
      if value.is_a?(Hash)
        its(:content) { should match "<#{key}" }
        #xmlタグ内のキーバリュー形式のパラメータ設定の確認
        value.each do |k,v|
          its(:content) { should match "#{k}=\"#{v}\"" }
        end
      #単一タグ形式のパラメータ値の確認
      elsif value.is_a?(String)
        if value.empty? then its(:content) { should match "<#{key}" } end
      end
    end
  end

#試験項目  :パラメタ設定 項目2 > 設定ファイルの確認
#環境定義書:ログローテーション設定(catalina.out)
#ロジック番号:01
  describe file(property[:tomcat][:logrotate_d_tomcat][:filepath]) do
    property[:tomcat][:logrotate_d_tomcat][:strings].each do |index,string_val|
      its(:content) { should match /#{string_val}/ }
    end
  end

#試験項目  :パラメタ設定 項目2 > 設定ファイルの確認
#環境定義書:エラーページ設定(web.xml)
#ロジック番号:01
  describe file('/opt/tomcat/conf/web.xml') do
    property[:tomcat][:web_xml][:multiline_strings].each do |index,str_val|
      its(:content) { should match /#{str_val}/m }
    end
  end

#試験項目  :パラメタ設定 項目2 > 設定ファイルの確認
#環境定義書:バージョン表示設定
#ロジック番号:01
  describe file('/opt/tomcat/lib/org/apache/catalina/util/ServerInfo.properties') do
    property[:tomcat][:ServerInfo_properties][:key_val].each do |key, value|
      its(:content) { should match "#{key}=#{value}" }
    end
  end

#試験項目  :ファイル配置 項目1 > ファイル配置の確認・パーミッション・オーナー設定確認
#環境定義書:-
#ロジック番号:01
  property[:tomcat][:conf_files].each do |key, value|
    describe file(value[:file]) do
      it { should exist }
      it { should be_file }
      it { should be_mode value[:permission] }
      it { should be_owned_by value[:owner] }
      it { should be_grouped_into value[:owner_group] }
    end
  end
  
#試験項目  :プロトコル・ポート 項目1 > TCPポート番号を確認
#環境定義書:-
#ロジック番号:01
  property[:tomcat][:ports].each do |index,paras|
    describe port(paras['number']) do
      it { should be_listening.with(paras['protocol']) }
    end
  end

#試験項目  :ソフトウェアバージョン 項目1 > Tomcatのバージョンの確認
#環境定義書:前提事項
  describe command('sh /opt/tomcat/bin/version.sh') do
    its(:stdout) { should match property[:tomcat][:versions][:tomcat] }
  end

#試験項目  :ソフトウェアバージョン 項目2 > JDKのインストールの確認
#環境定義書:前提事項
  describe command("/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.79.x86_64/jre/bin/java -version") do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should match property[:tomcat][:versions][:jdk] }
  end

#試験項目  :ソフトウェアバージョン 項目3 > JDBCドライバのインストールの確認
#環境定義書:- (インストール手順書に記載)
  describe file(property[:tomcat][:versions][:jdbc_driver] ) do
    it { should exist }
  end

#試験項目  :不要機能排除 項目1 > 不必要なサンプルアプリケーションの削除の確認
#環境定義書:-
#ロジック番号:01
  property[:tomcat][:deleted_sample_apps].each do |index,dir_name|
    describe file("/opt/tomcat/webapps/#{dir_name}") do
      it { should_not exist }
    end
  end

#end of shared_examples  
end