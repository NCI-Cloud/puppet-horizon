require 'spec_helper'

describe 'horizon::dashboards::designate' do

  let :params do
    {}
  end

  shared_examples_for 'horizon::dashboards::designate' do

    context 'with default parameters' do
      let(:pre_condition) do
        <<-eos
          class { 'horizon':
            secret_key => 'elj1IWiLoWHgcyYxFVLj7cM5rGOOxWl0',
          }
eos
      end

      it 'installs designate-dashboard package' do
        is_expected.to contain_package('designate-dashboard').with(
          :ensure => 'present',
          :name   => platform_params[:designate_dashboard_package_name],
          :tag    => ['openstack', 'horizon-package']
        )
      end

      it 'generates _1799_dns_settings.py' do
        verify_concat_fragment_contents(catalogue, '_1799_dns_settings.py', [
          "settings.POLICY_FILES.update({",
          "    'dns': 'designate_policy.yaml',",
          "})"
        ])
      end
    end

    context 'without the horizon class defined' do
      it { should raise_error(Puppet::Error) }
    end

    context 'with policy customization' do
      let(:pre_condition) do
        <<-eos
          class { 'horizon':
            secret_key        => 'elj1IWiLoWHgcyYxFVLj7cM5rGOOxWl0',
            policy_files_path => '/etc/openstack-dashboard',
          }
          class { 'horizon::policy': }
eos
      end

      before do
        params.merge!({
          :policies => {}
        })
      end

      it 'configures policy' do
        is_expected.to contain_horizon__policy__base('designate_policy.yaml').with(
          :policies     => {},
          :file_mode    => '0640',
          :file_format  => 'yaml',
          :purge_config => false,
        )
      end
    end

    context 'with policy customization but without the horizon::policy class' do
      let(:pre_condition) do
        <<-eos
          class { 'horizon':
            secret_key        => 'elj1IWiLoWHgcyYxFVLj7cM5rGOOxWl0',
            policy_files_path => '/etc/openstack-dashboard',
          }
eos
      end

      before do
        params.merge!({
          :policies => {}
        })
      end

      it { should raise_error(Puppet::Error) }
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      let(:platform_params) do
        case facts[:osfamily]
        when 'Debian'
          { :designate_dashboard_package_name => 'python3-designate-dashboard' }
        when 'RedHat'
          { :designate_dashboard_package_name => 'openstack-designate-ui' }
        end
      end

      it_behaves_like 'horizon::dashboards::designate'
    end
  end

end
