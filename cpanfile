requires "Carp" => "0";
requires "Data::Dumper" => "0";
requires "Locale::Maketext" => "1.22";
requires "Log::Log4perl" => "0";
requires "Moose" => "0";
requires "namespace::autoclean" => "0";

on 'test' => sub {
  requires "DBD::SQLite" => "0";
  requires "DBI" => "0";
  requires "File::Temp" => "0";
  requires "Test::More" => "0";
  requires "strict" => "0";
  requires "warnings" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};
