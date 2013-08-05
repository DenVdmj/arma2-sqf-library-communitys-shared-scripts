use strict;
use locale;
use POSIX;
use Win32::Registry;

my @filelist;
my $currentPath = POSIX::getcwd();
my $DIRSPACER = ' - ';
my @contentFileChunks = ();
my $targetPath = canonizePath("$currentPath/../doc/");
my $libPath = canonizePath("$currentPath/../css");
my $relPath = canonizePath("$currentPath/..");

mkdir $targetPath unless -e $targetPath;
unlink $_ for <$targetPath/*.*>;

walkDir(
    path => $libPath,
    proc => sub {
        my ($file, $deep) = @_;
        return if -d $file;

        #if ($file =~ /\.txt$/) {
        #    my $linkInfo = processFile($file, sub { my ($text, $filename) = @_; htmlFileTemplate($text, $file)});
        #    push(@contentFileChunks, qq(<a href="$linkInfo->{href}">/$linkInfo->{title}</a>\n));
        #};

        #if ($file =~ /(?:\.macro$)|(?:css$)/) {
        #    my $linkInfo = processFile($file, sub { my ($text, $filename) = @_; htmlFileTemplate($text, $file)});
        #    push(@contentFileChunks, qq(<a href="$linkInfo->{href}">/$linkInfo->{title}</a>\n));
        #};

        if ($file =~ /(?:\bcss\/[\w-]+\.macro$)|(?:\.sqf$)|(?:\bcss$)/) {
            my @content = parseSqfInlineDocs($file);
            if (scalar @content > 0) {
                my $linkInfo = processFile($file, $relPath, sub {
                    my ($text, $filename) = @_;
                    htmlFileTemplate(htmlTplBlock(join("<hr />", @content), $filename, $text), $filename);
                });
                push(@contentFileChunks, qq(<a href="$linkInfo->{href}">/$linkInfo->{title}</a>\n));
            } else {
                my $linkInfo = processFile($file, $relPath, sub {
                    my ($text, $filename) = @_;
                    htmlFileTemplate($text, $filename);
                });
                push(@contentFileChunks, qq(<a href="$linkInfo->{href}">/$linkInfo->{title}</a>\n));
            };
        };
    }
);

{
    local *fhContent;
    open(fhContent, "+>$targetPath/index.html") or die "$targetPath/index.html";
    print fhContent htmlTOCTemplate(join("", map {"<li>$_</li>"} @contentFileChunks));
    close(fhContent);
};

sub processFile {

    my $file = canonizePath(shift);
    my $targetdir = canonizePath(shift);
    my $callback = shift;
    my $relFileName = $file;
    $relFileName =~ s/^\Q$targetdir\E[\/\\]?//;
    my $htmlFileName = $relFileName;
    $htmlFileName =~ s/\/|\\/$DIRSPACER/g;
    $htmlFileName .= ".html";

    print qq(Process file: "$file"\n);

    {
        local *hndlOutFile;
        open(hndlOutFile, "+>$targetPath/$htmlFileName");
        print qq(Create doc: "$targetPath/$htmlFileName"\n);
        my $coloredText = getColoredText(qq(-h -imyshorttags "$file"));
        # удалить идентификационнцю строку колорера
        $coloredText =~ s/^Created with colorer-take5 library. Type '\w+'//;
        # удалить избыточные теги раскрашивани
        $coloredText =~ s/\<\/(\w)\>(\s*)\<\1\>/$2/ig;
        print hndlOutFile $callback->($coloredText, $relFileName);
        close(hndlOutFile);
    };
    return {
        'href' => $htmlFileName,
        'title' => $relFileName,
    }
}

sub parseSqfInlineDocs {

    my $sqfFileContent;
    my @content;

    {
        local *hndlOutFile;
        open(hndlOutFile, shift) or die;
        read(hndlOutFile, $sqfFileContent, -s hndlOutFile) or die;
        close(hndlOutFile);
    };

    while (
        $sqfFileContent =~ m<
             (?:\n//([\x20\x09]+)?(?:(?:function)\s+)?((func(?:\w+|\(\w+\))).*?)\n\s*\3\s*\=\s*) |
            (?:\*\n*([\x20\x09]+)?(?:(?:function)\s+)?((func(?:\w+|\(\w+\))).*?)\n\*/\s*\6\s*\=\s*)
        >gcisx
    ) {
        my $padding = $1 | $4;
        my $text = $2 | $5;

        $text = "Function $text";
        $text =~ s{\n//$padding?}{\n}g;
        $text =~ s{(//|\s)+$}{}g;

        my $html = escapeHTML($text);
        $html =~ s{^(Function func\(\w+\))?}{<h2>$1</h2>};
        $html =~ s{^((?:\w+(?:\s+\d+)?):\n?)}{<strong>$1</strong>}gm;

        push(@content, $html);
    };

    return @content;
};

# ------------------------------------------------------

sub getColoredText {
    my ($node, $type, $value);

    $::HKEY_CURRENT_USER->Open('Software\Colorer5', $node) or
        die 'Not open "Software\Colorer5"';

    $node->QueryValueEx('executable', $type, $value) or
        die 'Not found "colorer.exe", version 4you';

    local *fhInput;
    my $pid = open(fhInput, "-|", ($value." ".(shift)));
    my $result = join("", map {$_} <fhInput>);
    close(fhInput);
    $result;
};

sub walkDir {
    # ( path => string, opendir => sub, proc => sub, closedir => sub, sort => sub )
    my %arg = @_;
    my $deep = 0;
    walk($arg{'path'});

    sub walk {

        my ($path) = @_;

        $arg{'opendir'}->($path, $deep) if -d $path and $arg{'opendir'};

        $arg{'proc'}->($path, $deep);

        -d $path or return

        local *DIR;
        my $filename;
        opendir(*DIR, $path) or die;
        my @dirlist = readdir(*DIR);
        closedir(*DIR);

        for $filename ( sort { -d $path . '/' . $b cmp -d $path . '/' . $a } @dirlist ) {
            next if $filename eq '.' or $filename eq '..';
            ++$deep;
            walk->($path . '/' . $filename);
            $deep--;
        };
        $arg{'closedir'}->($path, $deep) if $arg{'closedir'};
    }
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

sub escapeHTML {
    $_[0] =~ s{[\<\>\&\"]}{
        {
            '<' => '&lt;',
            '>' => '&gt;',
            '&' => '&amp;',
            '"' => '&quot;'
        }->{$&}
    }eg;
    return $_[0];
};

sub htmlTplBlock {
    my ($content, $filename, $sourcecode) = @_;
    qq{<hr />$content<hr />
<a
  href="#unfoldcode"
  id="unfoldcode"
  onclick="
    var el = document.getElementById('sqfsrc');
    el.style.display = el.style.display == '' ? 'none' : ''
  "
>Source of &ldquo;$filename&rdquo;</a>
<div style='display: none' id='sqfsrc'>
<h2>&ldquo;$filename&rdquo;</h2>
$sourcecode
<hr />}
}

sub canonizePath {
    my $path = shift;
    my @pathChunks = split(/[\/\\]/, $path);
    my @canonizedPathChunks;
    for my $chunk (@pathChunks) {
        if ($chunk eq '..') {
            pop(@canonizedPathChunks);
        } else {
            push(@canonizedPathChunks, $chunk)
        }
    }
    return join('/', @canonizedPathChunks);
}

BEGIN {

    local *fhMainTpl;
    local *fhPageTpl;

    my $strMainTpl = "";
    my $strPageTpl = "";

    open fhMainTpl, "createdoc.pl.main.tpl.html" or die q(can't open tamplate file "createdoc.pl.main.tpl.html");
    read fhMainTpl, $strMainTpl, -s fhMainTpl;
    close fhMainTpl;

    open fhPageTpl, "createdoc.pl.page.tpl.html" or die q(can't open tamplate file "createdoc.pl.page.tpl.html");
    read fhPageTpl, $strPageTpl, -s fhPageTpl;
    close fhPageTpl;

    sub htmlTOCTemplate {
        return join(shift, split(/<!-- INSERT HERE -->/, $strMainTpl))
    };

    sub htmlFileTemplate {
        return (
            join(shift, split(/<!-- INSERT HERE -->/, join(shift, split(/<!-- INSERT FILENAME -->/, $strPageTpl))))
        )
    };
};
