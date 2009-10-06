use inc::Module::Install;
name 'Perlbal-Plugin-ProxyHost';
all_from 'lib/Perlbal/Plugin/ProxyHost.pm';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
