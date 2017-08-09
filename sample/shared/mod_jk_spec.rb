#
# Spec-file Name:: mod_jk_spec.rb
#
#試験項目  :基本動作確認項目(mod_jk)
#環境定義書:環境定義書(mod_jk)
#
# Copyright(c) 2015 NTTDATA Corporation.
#
shared_examples 'mod_jk_spec' do
#試験項目  :パラメタ設定 項番2 > 設定ファイルの確認
#環境定義書:基本設定(mod_jk.conf)
#ロジック番号:01
  describe file(property[:mod_jk][:filepath][:'mod_jk.conf']) do
    property[:mod_jk][:'mod_jk.conf'].each do |key, value|
      its(:content) { should match value }
    end
  end

#試験項目  :パラメタ設定 項番2 > 設定ファイルの確認
#環境定義書:worker設定(workers.properties)
#ロジック番号:01
  describe file(property[:mod_jk][:filepath][:'workers.properties']) do
    property[:mod_jk][:'workers.properties'][:key_val].each do |key, value|
      its(:content) { should match value }
    end
  end

#試験項目 :パラメタ設定 項番3 > コメントアウト解除の確認
#環境定義書:-
  describe file('/etc/httpd/conf/httpd.conf') do
      its(:content) { should match /^#{property[:mod_jk][:include_mod_jk]}/ }
  end

#試験項目  :パラメタ設定 項番4 > アクセス用パスワードファイルの作成の確認
#環境定義書:-
  describe file(property[:mod_jk][:filepath][:'jkstatus']) do
    its(:content) { should match "jkstatus:.*" }
  end

#試験項目  :ファイル配置 項番1 > ファイル配置の確認 パーミッション・オーナー設定確認
#環境定義書:-
#ロジック番号:01
  property[:mod_jk][:conf_files].each do |key, value|
    describe file(value[:file]) do
      it { should exist }
      it { should be_file }
      it { should be_mode value[:permission] }
      it { should be_owned_by value[:owner] }
      it { should be_grouped_into value[:owner_group] }
    end
  end

#試験項目  :ソフトウェアバージョン 項番1 > mod_jkのバージョンを確認
#環境定義書:前提事項
  describe command('strings /etc/httpd/modules/mod_jk.so | grep -i "mod_jk/"') do
    its(:stdout) { should match property[:mod_jk][:version] }
  end

#end of shared_examples  
end