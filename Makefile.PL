use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME' => 'Imager::DTP',
	'VERSION_FROM' => 'lib/Imager/DTP.pod',
	'PREREQ_PM' => {
		Imager => 0.39,
		Test::More => 0,
		utf8 => 0,
	},
);