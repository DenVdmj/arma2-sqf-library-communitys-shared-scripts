
mkdir 'css';

for my $filename (
    <../css/css>,
    <../css/lib/*.sqf>,
    <../css/lib/*.sqs>,
    <../css/*.macro>
) {
    my $filenameinfo = getFileNameInfo($filename);
    next unless $filenameinfo->{name} =~ /\w[\w.-]+/;
    printf(qq(copy and process file "%s" ---> "css/%s"\n), $filename, getFileNameInfo($filename)->{'file'});
    copyFile($filename, 'css/' . $filenameinfo->{file}, textReplace);
}

sub textReplace {
    my $contents = shift;
    $contents =~ s{((?:^|\n)\s*#\s*include\s*)"\\css\\([\w_.-]+)"}{$1"$2"}g;
    $contents =~ s{((?:^|\n)\s*#\s*define\s+__PATH__\s+)\\css\\(\w+)}{$1css}g;
    #$contents =~ s{((?:^|\n)\s*#\s*define\s+__PATH__\s+)\\css\\(\w+)}{$1$2}g;
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
