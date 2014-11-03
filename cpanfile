requires "Beam::Wire" => "0";
requires "Dancer" => "0";

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};
