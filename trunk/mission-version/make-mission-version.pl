
mkdir 'css';

for my $filename (<../css/lib/*.sqf>) {
    printf(qq("%s" --> "css/%s"), $filename, getFileNameInfo($filename)->{'file'});
    copyFile($filename, 'css/' . getFileNameInfo($filename)->{file}, textReplace);
}

for my $filename ('common', 'css', <../css/*.macro>) {
    printf(qq("../css/%s" --> "css/%s"\n), $filename, getFileNameInfo($filename)->{'file'});
    copyFile('../css/' . $filename, 'css/' . getFileNameInfo($filename)->{file}, textReplace);
}

sub textReplace {
    my $contents = shift;
    $contents =~ s{((?:^|\n)\s*#\s*include\s*)"\\css\\(\w+)"}{$1"$2"}g;
    $contents =~ s{((?:^|\n)\s*#\s*define\s+__PATH__\s+)\\css\\(\w+)}{$1$2}g;
    return $contents;
}

sub copyFile {
    my ($source, $destination) = @_;
    local *process = @_[2] or (sub {return shift});
    local *sourceFile, *destinationFile;
    my $contents;
    open(*sourceFile, $source) or return 0;
    my $len = -s *sourceFile;
    binmode(*sourceFile);
    sysread(*sourceFile, $contents, $len);
    close(*sourceFile);
    open(*destinationFile, '+>'.$destination) or return 0;
    binmode(*destinationFile);
    syswrite(*destinationFile, process($contents), $len);
    close(*destinationFile);
    return 1;
}

sub getFileNameInfo {
    my @p = split(/\\|\//, shift);
    my $l = @p - 1;
    my $f = $p[$l];
    my $r = rindex($f, '.');
    $r = length $f if $r <= 0;
    return {
        'path' =>\@p,
        'file' => $f,
        'dir'  => join('/', (@p[0 .. $l-1], '')),
        'name' => substr($f, 0, $r),
        'ext'  => substr($f, 1+ $r)
    }
};
