#
# Spec-file Name:: apache_spec.rb
#
#試験項目  :基本動作確認項目(Apache)
#環境定義書:環境定義書(Apache)
#
# Copyright(c) 2015 NTTDATA Corporation.
#
shared_examples 'apache_spec' do
  
#試験項目  :パラメタ設定 項番2 > 設定ファイルの確認
#環境定義書:動作モード選択（httpd）
#ロジック番号:01・03
  describe file('/etc/sysconfig/httpd') do
    property[:apache][:sysconfig_httpd].each do |key, value|
      if value == ''
        its(:content) { should_not match /^(\s*[^#]*\s*)#{key}/ }  #valueが設定されてない場合、対応するkeyが存在しないことを確認
      else
        its(:content) { should match /^#{value}/ }  #valueが設定されている場合、対応するkeyの値を確認
      end
    end
  end

#試験項目  :パラメタ設定 項番2 > 設定ファイルの確認
#環境定義書:基本設定(httpd.conf)
#ロジック番号:02・03
  describe file('/etc/httpd/conf/httpd.conf') do
    #パラメータ設定の確認
    property[:apache][:httpd_conf][:EXISTS].each do |key, value|
      #ハッシュパラメータの確認
      if value.is_a?(Hash)
        value.each do |k,v|
          it { should contain "#{k} #{v}" }
        end
      #配列パラメータの確認
      elsif value.is_a?(Array)
        value.each do |v|
          it { should contain "#{key} #{v}" }
        end
      #単一パラメータの確認
      else
        it { should contain "#{key} #{value}" }
      end
    end
    #コメントアウトされているパラメータの確認
    property[:apache][:httpd_conf][:COMMENT_OUT].each do |key, value|
      #ハッシュパラメータの確認
      if value.is_a?(Hash)
        value.each do |k,v|
          its(:content) { should_not match /^(\s*[^#]*\s*)#{k} #{v}/ }
        end
      #配列パラメータの確認
      elsif value.is_a?(Array)
        value.each do |v|
          its(:content) { should_not match /^(\s*[^#]*\s*)#{key} #{v}/ }
        end
      #単一パラメータの確認
      else
        its(:content) { should_not match /^(\s*[^#]*\s*)#{key} #{value}/ }
      end
    end   
  end

#試験項目  :パラメタ設定 項番2 > 設定ファイルの確認
#環境定義書:ログローテーション基本設定
#ロジック番号:01
  describe file('/etc/logrotate.d/httpd') do
    property[:apache][:logrotate].each do |value|
      it { should contain value}
    end
  end

#試験項目  :パラメタ設定 項番3 > staticモジュールの確認
#環境定義書:-
#ロジック番号:01
  describe command('httpd -l') do
    property[:apache][:static_module].each do |value|
      its(:stdout) { should match value }
    end
  end
  
#試験項目  :パラメタ設定 項番4 > DSOの確認
#環境定義書: 基本設定(httpd.conf)
#ロジック番号:01
  property[:apache][:modules].each do |key, value|
    describe file("/etc/httpd/modules/#{value}") do
      it { should exist }
    end
  end

#試験項目  :パラメタ設定 項番6 > faviconの確認
#環境定義書: -
  describe command('ls /var/www/html/ | grep favicon') do
    its(:exit_status) { should eq 0 }
  end

#試験項目  : ファイル配置の確認 項番1 > パーミッション・オーナー設定確認
#環境定義書:-
#ロジック番号:01
  property[:apache][:conf_files].each do |key, value|
    describe file(value[:file])do
      it { should exist }
      it { should be_file }
      it { should be_owned_by value[:owner] }
      it { should be_mode value[:permission] }
    end
  end

#試験項目  : プロセス > Apacheの起動プロセスを確認
#環境定義書:-
  #サービス状況の確認
  describe service('httpd') do
    it { should be_running }
  end
  
  #httpd.workerの確認
  describe command('ps -ef | grep httpd.worker | grep -v grep | wc -l') do
    it(:stdout) { should_not eq 0 }
  end

#試験項目  :プロトコル・ポート 項番1 > TCPポート番号を確認
#試験項目  :プロトコル・ポート 項番2 > TCPポート番号(SSL)を確認
#環境定義書:-
#ロジック番号:01
  property[:apache][:port].each do |protocol_name,value|
    describe port(value) do
      it { should be_listening.with('tcp') }
    end
  end

#試験項目  : ソフトウェアバージョン 項番1 >  Apacheのバージョンを確認
#環境定義書:前提事項
#ロジック番号:01
  #パッケージの確認
  property[:apache][:version].each do |key, value|
    describe package(key) do
      it { should be_installed.by('rpm').with_version(value) }
    end  
  end
  
  #httpd.workerでの確認
  describe command('/usr/sbin/httpd.worker -v') do
    its(:stdout) { should match property[:apache][:'httpd.worker_version'] }
  end
  
end
