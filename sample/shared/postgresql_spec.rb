#
# Spec-file Name:: postgresql_spec.rb
#
#試験項目  :基本動作確認項目(PostgreSQL)
#環境定義書:環境定義書(PostgreSQL)
#
# Copyright(c) 2015 NTTDATA Corporation.
#
shared_examples 'postgresql_spec' do

#試験項目  :パラメタ設定 項番3 > GUCパラメータの確認
#環境定義書:基本設定(postgresql.conf)
#ロジック番号:01
  #psqlコマンドで確認
  property[:postgresql][:postgresql_conf][:psql_key_val].each do |key,val|
   describe command("psql -h 127.0.0.1 -U #{property[:postgresql][:user]} -c \"show #{key} ;\"") do
     its(:stdout) { should match /^\s*#{val}$/ }
   end
  end

  #構成ファイルで確認
  describe file('/database/pgdata/data/postgresql.conf') do
    property[:postgresql][:postgresql_conf][:file_key_val].each do |key, value|
      its(:content) { should match "#{key}\s*=\s*#{value}" }
    end
  end

#試験項目  :パラメタ設定 項番4 > 設定ファイルの確認
#環境定義書:クライアントアクセス設定(pg_hba.conf)
#ロジック番号:01
  describe file(property[:postgresql][:pg_hba][:path]) do
    #設定するパラメータの確認
    property[:postgresql][:pg_hba][:entries].each do |index,paras|
      para_str = "#{paras['TYPE']}\s+#{paras['DATABASE']}\s+#{paras['USER']}\s+#{paras['CIDR ADDRESS']}\s+#{paras['METHOD']}"
      its(:content) { should match para_str }
    end
    #コメントアウトするパラメータの確認
    property[:postgresql][:pg_hba][:comment_out_entries].each do |index,paras|
      para_str = "#{paras['TYPE']}\s+#{paras['DATABASE']}\s+#{paras['USER']}\s+#{paras['CIDR ADDRESS']}\s+#{paras['METHOD']}"
      its(:content) { should_not match /^(\s*[^#]*?[\s,;]|)#{para_str}/ }      
    end
  end

#試験項目  :パラメタ設定 項番5 > postgresユーザ環境変数の確認
#環境定義書:ユーザ設定
#ロジック番号:01
  #envコマンドで確認
  describe command("su - #{property[:postgresql][:user]} -c 'env'") do
    property[:postgresql][:env][:key_val].each do |key, value|
      its(:stdout) { should match "^#{key}=#{value}$" }
    end
  end

  #シンボリックリンクの設定を確認
  describe file(property[:postgresql][:pgsql_bashrc][:path]) do
  	it { should be_linked_to property[:postgresql][:pgsql_bashrc][:linked_to]}
  end

#試験項目  :パラメタ設定 項番7 > ログの確認
#環境定義書:不要ログ削除設定
#ロジック番号:01
  #ログファイルのファイル名確認
  describe command("ls -l #{property[:postgresql][:log_files][:path]}") do
    property[:postgresql][:log_files][:file_name_patterns].each do |index,pattern_string| 
      its(:stdout) { should match pattern_string }
    end
  end

#試験項目  :パラメタ設定 項番9 > pg_stats_reporter設定確認
#環境定義書:pg_stats_reporter設定
#ロジック番号:01
  describe file('/var/www/pg_stats_reporter/pg_stats_reporter.ini') do
    property[:postgresql][:pg_stats_reporter][:key_val].each do |key, value|
      its(:content) { should match "#{key}\s*=\s*#{value}" }
    end

    property[:postgresql][:pg_stats_reporter][:strings].each do |index,string_val|
      its(:content) { should match /#{string_val}/ }
    end
  end

#試験項目  :パラメタ設定 項番8 > 起動スクリプトの確認
#試験項目  :パラメタ設定 項番9 > pg_stats_reporter設定確認
#環境定義書:-
#ロジック番号:02と03
  #chkconfigで確認
  property[:postgresql][:services].each do |svc_name,run_lv_str|
    run_lv_list = "0123456".split(//) #ランレベルのリストの初期化
    run_lv_list.each do |lv|
      describe service(svc_name) do
        if run_lv_str.include?(lv)  #onのランレベルの確認
          it { should be_enabled.with_level(lv.to_i) }
        else  #offのランレベルの確認
          it { should_not be_enabled.with_level(lv.to_i) }
        end
      end
    end
  end

#試験項目  :ファイル配置 項番1 > ファイル配置の確認(パーミッション・オーナー設定確認)
#環境定義書:-
#ロジック番号:01
  property[:postgresql][:conf_files].each do |file_name,paras|
    describe file(paras['filepath']) do
      it { should be_file }
      it { should be_mode paras['permission'] }
      it { should be_owned_by paras['owner'] }
      it { should be_grouped_into paras['owner_group']}
    end
  end

#試験項目  :ログイン 項番1 > DBサーバーへの接続
#環境定義書:-
  describe command("su - #{property[:postgresql][:user]} -c 'whoami'") do
    its(:stdout) { should match property[:postgresql][:user] }
  end

#試験項目  :機能単体 項番12 > データベース一覧の取得の確認
#環境定義書:-
#ロジック番号:01
  describe command("su - #{property[:postgresql][:user]} -c 'psql -l'") do
    property[:postgresql][:db_list].each do |index,db_str|
      its(:stdout) { should match db_str }
    end
  end

#試験項目  :プロセス 項番1 > PostgreSQLの起動プロセスを確認
#環境定義書:-
#ロジック番号:01
  describe command("ps -ef | grep postgres | grep -v grep") do
    property[:postgresql][:running_processes].each do |index,process_name|
      its(:stdout) { should match process_name }
    end
  end

#試験項目  :ソフトウェアバージョン 項番1 > PostgreSQLのバージョンを確認
#環境定義書:-
   describe command("psql -U #{property[:postgresql][:user]} -c 'select version();'") do
    its(:stdout) { should match property[:postgresql][:select_version] }
   end

#end of shared_examples
end