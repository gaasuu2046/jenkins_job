#
# Spec-file Name:: rhel_spec.rb
#
#試験項目  :基本動作確認項目(RHEL)
#環境定義書:環境定義書(RHEL)
#
# Copyright(c) 2015 NTTDATA Corporation.
#
shared_examples 'rhel_spec' do
  
#試験項目  :ソフトウェアバージョン 項番1 > OSのバージョンの確認
#環境定義書:インストール情報(OSリリースバージョン)
  describe file('/etc/redhat-release') do
    its(:content) { should match property[:rhel][:os_version] }
  end

#試験項目  :ソフトウェアバージョン 項番2 > カーネルのバージョンの確認
#環境定義書:インストール情報(カーネルバージョン)
  describe 'kernel version' do
    context linux_kernel_parameter('kernel.osrelease') do
      its(:value) { should eq property[:rhel][:kernel_version] }
    end
  end

#試験項目  :ソフトウェアバージョン 項番3 > パッケージのバージョンの確認
#環境定義書:追加パッケージ
#ロジック番号:01・03
  property[:rhel][:additional_package_rpm].each do |package_name,ver|
    describe package(package_name) do
      #バージョンが指定されているパッケージの確認
      if ver.empty?
        it { should be_installed.by('rpm') }
      #バージョンが指定されていないパッケージの確認
      else
        it { should be_installed.by('rpm').with_version(ver) }
      end
    end
  end

#試験項目  :パラメタ設定 項番1 > OSプラットフォームの確認
#環境定義書:インストール情報(プラットフォーム)
  describe command('uname -i') do
    its(:stdout) { should match property[:rhel][:platform_info] }
  end

#試験項目  :パラメタ設定 項番3 > システム標準言語の確認
#環境定義書:インストール情報(システム標準言語)
  describe file('/etc/sysconfig/i18n') do
    its(:content) { should match property[:rhel][:system_lang] }
  end

#試験項目  :パラメタ設定 項番4 > キーボードのタイプの確認
#環境定義書:インストール情報(キーボードのタイプ)
  describe file('/etc/sysconfig/keyboard') do
    its(:content) { should match property[:rhel][:keyboard] }
  end

#試験項目  :パラメタ設定 項番5 > ブートローダの設定確認
#環境定義書:カーネル起動パラメータ
#ロジック番号:01
  describe file(property[:rhel][:grub_conf][:filepath]) do
    property[:rhel][:grub_conf][:key_val].each do |key, value|
      its(:content) { should match "#{key}=#{value}" }
    end
  end

#試験項目  :パラメタ設定 項番6 > タイムゾーン設定確認
#環境定義書:インストール情報(タイムゾーン)
  #タイムゾーンの確認
  describe file('/etc/sysconfig/clock') do
    its(:content) { should match property[:rhel][:timezone] }
  end

  #UTCモードの確認
  describe file('/etc/adjtime') do
    its(:content) { should match property[:rhel][:utc_mode] }
  end

#試験項目  :パラメタ設定 項番7 > ファイアウォールの設定確認
#環境定義書:-
#ロジック番号:01
  #iptablesサービスの確認
  describe file('/etc/sysconfig/iptables') do
    it { should_not exist }
  end

  #iptablesルールの確認
  property[:rhel][:iptables_rules].each do |rule_name,val|
    describe command ("iptables -L #{rule_name} | tail -n+3") do
      its(:stdout) { should match val }
    end
  end

#試験項目  :パラメタ設定　項番8 > SELinuxの設定確認
#環境定義書:SELinux
  describe selinux do
    it { should be_disabled }
  end

#試験項目  :パラメタ設定 項番9 > kdumpの有効化確認
#環境定義書:-
  describe service('kdump') do
    it { should be_running }
  end

#試験項目  :パラメタ設定　項番10 > ntpdの有効化確認
#環境定義書:-
  describe service ('ntpd') do
    it { should be_running }
  end

#試験項目  :パラメタ設定 項番13 > ホスト名の確認
#環境定義書:ホスト名
#ロジック番号:01
  #ホスト名の確認
  describe 'hostname' do
    context linux_kernel_parameter('kernel.hostname') do
      its(:value) { should eq property[:node][:sysconfig_network]['HOSTNAME'] }
    end
  end

  #networkファイルの確認
  describe file('/etc/sysconfig/network') do
    property[:node][:sysconfig_network].each do |key, value|
      its(:content) { should match "#{key}=#{value}" }
    end
  end

#試験項目  :パラメタ設定 項番14 > ネットワークインターフェース設定の確認
#環境定義書:ネットワークインタフェース
#ロジック番号:02・03
  property[:node][:interfaces].each do |interface_name,paras|
    #ネットワークインタフェースの存在の確認
    describe interface(interface_name) do
      it { should exist }
    end
    #ネットワークインタフェースのパラメータ設定の確認
    describe file("/etc/sysconfig/network-scripts/ifcfg-#{interface_name}") do
      paras.each do |para_name,val|
        #valが設定されていない場合、para_nameが存在しないことを確認
        if val.empty?
          its(:content) { should_not match /^(\s*[^#]*?[\s,;]|)#{para_name}/ }
        #valが設定されえている場合、para_nameの値を確認
        else
          its(:content) { should match /#{para_name}=#{val}/ }
        end
      end
    end
  end

#試験項目  :パラメタ設定 項番15 > ホストファイルによる名前の解決の確認
#環境定義書:名前解決定義
#ロジック番号:02・03
  property[:rhel][:hosts].each do |ip,hostnames|
    hostnames.each do |hostname|
      #ホスト名・ドメインが解決できることの確認
      describe host(hostname) do
        it { should be_resolvable.by('hosts') }
      end
      describe command("getent hosts \"#{ip}\"") do
        its(:stdout) {should match /#{hostname}\s/}
      end
    end
  end

#試験項目  :パラメタ設定 項番15 > ホストファイルによる名前の解決の確認
#環境定義書:名前解決方法
#ロジック番号:01
  describe file('/etc/nsswitch.conf') do
    property[:rhel][:nsswitch].each do |key, value|
      its(:content) { should match "#{key}:\s*#{value}" }
    end
  end

#試験項目  :パラメタ設定 項番16 > グループ/ユーザの確認
#環境定義書:ユーザ
#ロジック番号:01
  property[:rhel][:users].each do |username,params|
    describe user(username) do
      it { should exist }
      it { should have_uid params['uid'] }
      it { should belong_to_primary_group params['gname'] }
      it { should have_home_directory params['home_dir'] }
      it { should have_login_shell params['login_shell'] }
    end
  end

#試験項目  :パラメタ設定 項番16 > グループ/ユーザの確認
#環境定義書:グループ
#ロジック番号:02・03・04
  property[:rhel][:groups].each do |groupname,paras|
    #グループidの確認
    describe group(groupname) do
      it { should exist }
      it { should have_gid paras['gid'] }
    end
    #グループ　メンバーの確認
    describe command("lid -g #{groupname}") do
      unless paras['members'].nil? then
        paras['members'].each do |groupmember|
          its(:stdout) { should match groupmember }
        end
      end
    end
    #グループメンバー数の確認
    describe command("lid -g #{groupname} | wc -l") do
      if paras['members'].nil? then
        its(:stdout) { should match /^0$/ }
      else
        its(:stdout) { should match /^#{paras['members'].size}$/ }
      end
    end
  end

#試験項目  :パラメタ設定 項番17 > ユーザプロファイルの確認
#環境定義書:プロファイル
#ロジック番号:01    
  describe file('/etc/profile') do
    property[:rhel][:profile].each do |index,profile_entry|
      its(:content) { should match /#{profile_entry}/ }
    end    
  end

#試験項目  :パラメタ設定 項番18 > Upstartの確認
#環境定義書:upstart(init)
#ロジック番号:01
  describe file('/etc/init/control-alt-delete.conf') do
    #削除およびコメントアウトされる項目の確認
    property[:rhel][:control_alt_delete][:comment_out].each do |index,item|
      its(:content) { should_not match /^(\s*[^#]*?[\s,;]|)#{item}/ }
    end
    #設定されている項目の確認
    its(:content) { should match property[:rhel][:control_alt_delete][:exec] }
  end

#試験項目  :パラメタ設定 項番19 > kdumpマウント設定の確認
#環境定義書:ファイルシステムタブ
#ロジック番号:01
  describe file('/etc/fstab') do
    property[:rhel][:fstab].each do |index,fstab_entry|
      its(:content) { should match fstab_entry }
    end
  end

#試験項目  :パラメタ設定 項番20 > カーネルパラメータの確認
#環境定義書:カーネルパラメータ
#ロジック番号:01
  describe 'sysctl.conf parameters' do
    property[:rhel][:sysctl].each do |key,val|
      context linux_kernel_parameter(key) do
        its(:value) { should match val }
      end
    end
  end

#試験項目  :パラメタ設定 項番21 ディスク情報（パーティション）の確認
#環境定義書:ディスク情報
#ロジック番号:02
  property[:node][:disks].each do |disk_path,paras|
    paras.each do |col_name,val|
      val=val*1024*1024 if col_name == 'SIZE'  #パラメータ名がSIZEの場合KB単位に変換。
      #ディスクのパラメータ値を取得
      describe command("lsblk -bn --output \"#{col_name}\" #{disk_path}") do
        its(:stdout) { should match "^#{val}$" }
      end
    end
  end

#試験項目  :パラメタ設定 項番22 > kdumpの確認
#環境定義書:ダンプ
#ロジック番号:01
  describe file('/etc/kdump.conf') do
    property[:rhel][:kdump].each do |key, value|
      its(:content) { should match "#{key}\s+#{value}" }
    end
  end

#試験項目  :パラメタ設定 項番23 > ABRTの確認
#環境定義書:ABRT
#ロジック番号:01
  #abrt-action-save-package-data.confの設定確認
  describe file('/etc/abrt/abrt-action-save-package-data.conf') do
    property[:rhel][:abrt_action_save_package_data][:key_val].each do |key, value|
      its(:content) { should match "#{key}\s*=\s*#{value}" }
    end
  end

  #abrt.confの設定確認
  describe file('/etc/abrt/abrt.conf') do
    #設定されている項目の確認
    property[:rhel][:abrt][:key_val].each do |key, value|
      its(:content) { should match "#{key}\s*=\s*#{value}" }
    end
    #削除およびコメントアウトされている項目の確認
    property[:rhel][:abrt][:comment_out].each do |index,item|
      its(:content) { should_not match /^(\s*[^#]*?[\s,;]|)#{item}/ }
    end  
  end

  #ccpp_event.confの設定確認
  describe file('/etc/libreport/events.d/ccpp_event.conf') do
    #削除およびコメントアウトされている項目の確認
    property[:rhel][:ccpp_event][:comment_out].each do |index,item|
      its(:content) { should_not match /^(\s*[^#]*?[\s,;]|)#{item}/ }
    end
  end

  #abrt_event.confの削除およびコメントアウトされている設定の確認
  describe file('/etc/libreport/events.d/abrt_event.conf') do
    #削除およびコメントアウトされている項目の確認
    property[:rhel][:abrt_event][:comment_out].each do |index,item|
      its(:content) { should_not match /^(\s*[^#]*?[\s,;]|)#{item}/ }
    end
  end

  #CCpp.confの設定確認
  describe file('/etc/abrt/plugins/CCpp.conf') do
    #設定されている項目の確認
    property[:rhel][:ccpp][:key_val].each do |key, value|
      its(:content) { should match "#{key}\s*=\s*#{value}" }
    end
  end

#試験項目  :パラメタ設定 項番24 > ユーザリミットの確認
#環境定義書:ユーザリミット
#ロジック番号:01
  #limits.conf
  describe file('/etc/security/limits.conf') do
    #設定されている項目の確認
    property[:rhel][:limits].each do |index,string_val|
      its(:content) { should match /#{string_val}/ }
    end
  end

  #90-nproc.conf
  describe file('/etc/security/limits.d/90-nproc.conf') do
    #設定されている項目の確認
    property[:rhel][:nproc_90].each do |index,string_val|
      its(:content) { should match /#{string_val}/ }
    end
  end

#試験項目  :パラメタ設定 項番24 > ユーザリミットの確認
#環境定義書:pam.dのlogin設定
#ロジック番号:01
  describe file('/etc/pam.d/login') do
    #設定されている項目の確認
    property[:rhel][:pam_d_login].each do |index,string_val|
      its(:content) { should match /#{string_val}/ }
    end
  end

#試験項目  :パラメタ設定 項番25 > pam.dのsu設定
#環境定義書:pam.dのsu設定
#ロジック番号:01
  describe file('/etc/pam.d/su') do
    #設定されている項目の確認
    property[:rhel][:pam_d_su].each do |index,string_val|
      its(:content) { should match /#{string_val}/ }
    end
  end

#試験項目  :パラメタ設定 項番26 > ntpの設定
#環境定義書:NTPクライアント
#ロジック番号:01
  #ntp.confの確認
  describe file('/etc/ntp.conf') do
    #設定されている項目の確認
    property[:rhel][:ntp_conf][:strings].each do |index,string_val|
      its(:content) { should match /#{string_val}/ }
    end
    #削除およびコメントアウトされている項目の確認
    property[:rhel][:ntp_conf][:comment_out].each do |index,item|
      its(:content) { should_not match /^(\s*[^#]*?[\s,;]|)#{item}/ }
    end
  end

  #ntpdateの確認
  describe file('/etc/sysconfig/ntpd') do
    property[:rhel][:sysconfig_ntpd].each do |key, value|
      its(:content) { should match "#{key}=#{value}" }
    end
  end

#試験項目  :パラメタ設定 項番26 > ntpの設定
#環境定義書:NTPデーモン
#ロジック番号:01
  describe file('/etc/sysconfig/ntpdate') do
    property[:rhel][:ntpdate].each do |key, value|
      its(:content) { should match "#{key}=#{value}" }
    end
  end

#試験項目  :パラメタ設定 項番27 > rsyslogの確認
#環境定義書:rsyslog
#ロジック番号:01
  describe file('/etc/rsyslog.conf') do
    #削除およびコメントアウトされている項目の確認
    property[:rhel][:rsyslog][:comment_out].each do |index,item|
      its(:content) { should_not match /^(\s*[^#]*?[\s,;]|)#{item}/ }
    end
    #インデックス形式の設定値の確認
    property[:rhel][:rsyslog][:strings].each do |index,string_val|
      its(:content) { should match /#{string_val}/ }
    end
    #キーバリュー形式の設定値の確認
    property[:rhel][:rsyslog][:key_val].each do |key, value|
      its(:content) { should match "#{key}\s+#{value}" }
    end
  end

#試験項目  :パラメタ設定 項番28 > ログローテーションの確認（共通設定）
#環境定義書:ログローテーション共通
#ロジック番号:01
  describe file('/etc/logrotate.conf') do
    #削除およびコメントアウトされている項目の確認
    property[:rhel][:logrotate_conf][:undefined_or_comment_out].each do |index,item|
      its(:content) { should_not match /^(\s*[^#]*?[\s,;]|)#{item}/ }
    end
    #設定されている項目の確認
    property[:rhel][:logrotate_conf][:strings].each do |index,string_val|
      its(:content) { should match /#{string_val}/ }
    end
  end

#試験項目  :パラメタ設定 項番30 > ログローテーションの確認（個別設定）
#環境定義書:ログローテーション個別(OS)
#ロジック番号:01
  #logrotate.d/syslogの確認
  describe file('/etc/logrotate.d/syslog') do
    #単一行の設定値の確認
    property[:rhel][:logrotate_d][:syslog][:strings].each do |index,string_val|
      its(:content) { should match /#{string_val}/ }
    end
    #複数行の設定値の確認
    property[:rhel][:logrotate_d][:syslog][:block_strings].each do |index,item|
      its(:content) { should match /#{item['start']}(.*?)#{item['string']}(.*?)#{item['end']}/m }
    end
  end

  #logrotate.d/snmpdの確認
  describe file('/etc/logrotate.d/snmpd') do
    #単一行の設定値の確認
    property[:rhel][:logrotate_d][:snmpd][:strings].each do |index,string_val|
      its(:content) { should match /#{string_val}/ }
    end
    #複数行の設定値の確認
    property[:rhel][:logrotate_d][:snmpd][:block_strings].each do |index,item|
      its(:content) { should match /#{item['start']}(.*?)#{item['string']}(.*?)#{item['end']}/m }
    end
  end

#試験項目  :パラメタ設定 項番31 > cron設定の確認
#環境定義書:cron
  describe cron do
    it { should have_entry(property[:rhel][:cron][:root]).with_user('root') }
  end

#試験項目  :パラメタ設定 項番32 > crontab設定の確認
#環境定義書:crontab
#ロジック番号:01
  describe file('/etc/crontab') do
    property[:rhel][:crontab].each do |key, value|
      its(:content) { should match "#{key}=#{value}" }
    end
  end

#試験項目  :パラメタ設定 項番33 > anacrontab設定の確認
#環境定義書:anacrontab
#ロジック番号:01
  describe file('/etc/anacrontab') do
    #キーバリュー形式の設定値の確認
    property[:rhel][:anacrontab][:key_val].each do |key, value|
      its(:content) { should match "#{key}=#{value}" }
    end
    #単一行の設定値の確認
    property[:rhel][:anacrontab][:strings].each do |index,string_val|
      its(:content) { should match /#{string_val}/ }
    end
  end

#試験項目  :パラメタ設定 項番34 > cron(0hourly)の確認
#環境定義書:cron(0hourly) 
#ロジック番号:01
  describe file('/etc/cron.d/0hourly') do
    #キーバリュー形式の設定値の確認
    property[:rhel][:cron_d_0hourly][:key_val].each do |key, value|
      its(:content) { should match "#{key}=#{value}" }
    end
    #単一行の設定値の確認
    property[:rhel][:cron_d_0hourly][:strings].each do |index,string_val|
      its(:content) { should match /#{string_val}/ }
    end
  end

#試験項目  :パラメタ設定 項番35 > cronジョブの確認
#環境定義書:cronジョブ
#ロジック番号:01
  #存在するファイルの確認
  property[:rhel][:cron_jobs].each do |job_name,job_path|
    describe file("#{job_path}#{job_name}") do
      it { should exist }
    end
  end
  #存在しないファイルの確認
  property[:rhel][:cron_jobs_not].each do |job_name,job_path|
    describe file("#{job_path}#{job_name}") do
      it { should_not exist }
    end
  end

#試験項目  :パラメタ設定 項番36 > Net-SNMP設定の確認
#環境定義書:Net-SNMP(1)
#ロジック番号:01
  describe file('/etc/snmp/snmpd.conf') do
    #設定されている項目の確認
    property[:rhel][:snmpd_conf][:values].each do |index,snmpd_conf_entry|
      its(:content) { should match snmpd_conf_entry }
    end
    #削除およびコメントアウトされている項目の確認
    property[:rhel][:snmpd_conf][:comment_out].each do |index,item|
      its(:content) { should_not match /^(\s*[^#]*?[\s,;]|)#{item}/ }
    end
  end

#試験項目  :パラメタ設定 項番36 > Net-SNMP設定の確認
#環境定義書:Net-SNMP(2)
#ロジック番号:01
  describe file('/etc/sysconfig/snmpd') do
    property[:rhel][:sysconfig_snmpd][:key_val].each do |key, value|
      its(:content) { should match "#{key}=#{value}" }
    end
  end

#試験項目  :パラメタ設定 項番37 > ストレージマウントポイントの確認
#環境定義書:ストレージマウントポイント
#ロジック番号:01と04
  unless property[:node][:storage_mount_point].nil? then
    property[:node][:storage_mount_point].each do |mount_point,paras|
      #マウント先ディレクトリーのオーナーとグループの確認
      describe file(mount_point) do
        it { should be_directory }
        it { should be_owned_by paras['owner'] }
        it { should be_grouped_into paras['owner_group'] }        
      end
      #Maximum mount countの確認
      describe command("tune2fs -l #{paras['partition']} | grep 'Maximum mount count'") do
        its(:stdout) { should match /\s#{paras['Maximum mount count']}(\s|$)/ }
      end
      #Check intervalの確認
      describe command("tune2fs -l #{paras['partition']} | grep 'Check interval'") do
        its(:stdout) { should match /\s#{paras['Check interval']}(\s|$)/ }
      end
    end
  end

#試験項目  :パラメタ設定 項番41 > リゾルバの確認
#環境定義書:リゾルバ
#ロジック番号:01
  describe file('/etc/resolv.conf') do
    property[:rhel][:resolv][:comment_out].each do |index,item|
      its(:content) { should_not match /^(\s*[^#]*?[\s,;]|)#{item}/ }
    end
  end

#試験項目  :パラメタ設定　項番42 > sudoの確認
#環境定義書:sudo
#ロジック番号:01
  describe file('/etc/sudoers') do
    #設定されている項目の確認
    property[:rhel][:sudoers][:sudoope].each do |index,sudoers_entry|
      its(:content) { should match sudoers_entry}
    end
    #削除およびコメントアウトされている項目の確認
    property[:rhel][:sudoers][:comment_out].each do |index,item|
      its(:content) { should_not match /^(\s*[^#]*?[\s,;]|)#{item}/ }
    end
  end

#試験項目  :パラメタ設定　項番45 > パッケージのバージョンの確認
#環境定義書:追加パッケージ
#ロジック番号:01と04
  unless property[:rhel][:additional_package_yum].nil? then
    describe command("yum list installed") do
      property[:rhel][:additional_package_yum].each do |package_name,ver|
        its(:stdout) { should match /#{package_name} \s*#{ver}/}
      end
    end
  end

#試験項目  :IPアドレス設定 項番1 > ipv6設定の確認
#環境定義書:modprobe
#ロジック番号:01
  describe file('/etc/modprobe.d/disable_ipv6.conf') do
    property[:rhel][:disable_ipv6].each do |index,string_val|
      its(:content) { should match /#{string_val}/ }
    end
  end

#試験項目  :プロセス 項番1 > OS（本体）のランレベルの確認
#環境定義書:ランレベル
#ロジック番号:01
  describe file('/etc/inittab') do
    property[:rhel][:inittab].each do |index,string_val|
      its(:content) { should match /#{string_val}/ }
    end
  end

#試験項目  :プロセス 項番2 > 起動サービスの対象・ランレベルの確認
#環境定義書:起動サービス
#ロジック番号:02と03
  #chkconfigで確認
  property[:rhel][:services].each do |svc_name,run_lv_str|
    run_lv_list = "0123456".split(//)  #ランレベルのリストの初期化
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

#試験項目  :確認漏れの環境定義書シート
#環境定義書:pam.dのpassword-auth設定
#ロジック番号:01
  describe file('/etc/pam.d/password-auth') do
    #pam_cracklib.so後に記述されている設定値の確認
    property[:rhel][:password_auth][:pam_cracklib_so].each do |key, value|
      it { should contain("#{key}=#{value}").after('pam_cracklib.so')}
    end
    #pam_tally2.so後に記述されている設定値の確認
    property[:rhel][:password_auth][:pam_tally2_so].each do |key, value|
      it { should contain("#{key}=#{value}").after('pam_tally2.so')}
    end
  end

#試験項目  :確認漏れの環境定義書シート
#環境定義書:遠隔ログイン設定
#ロジック番号:01と04
  #pam.d/sshdの確認
  describe file('/etc/pam.d/sshd') do
    property[:rhel][:pam_d_sshd].each do |index,string_val|
      its(:content) { should match /#{string_val}/ }
    end
  end

  #security/access.confの確認
  describe file('/etc/security/access.conf') do
    property[:rhel][:access_conf].each do |index,string_val|
      its(:content) { should match /#{string_val}/ }
    end
  end

  #security/access_sshd.confの確認
  describe file('/etc/security/access_sshd.conf') do
    unless property[:rhel][:access_sshd_conf].nil? then
      property[:rhel][:access_sshd_conf].each do |index,string_val|
        its(:content) { should match /#{string_val}/ }
      end
    end
  end

  #ssh/sshd_configの確認
  describe file('/etc/ssh/sshd_config') do
    #キーバリュー形式の設定値の確認
    property[:node][:sshd_config][:key_val].each do |key, value|
      its(:content) { should match "#{key}\s+#{value}" }
    end
    #単一行形式の設定値の確認
    unless property[:node][:sshd_config][:strings].nil? then
      property[:node][:sshd_config][:strings].each do |index,string_val|
        its(:content) { should match /#{string_val}/ }
      end
    end
  end
 
 #end of shared_examples
 end