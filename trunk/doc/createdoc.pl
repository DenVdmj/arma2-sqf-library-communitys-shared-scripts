use strict;
use locale;
use POSIX;
use Win32::Registry;

my @filelist;
my $currentPath = POSIX::getcwd();
my $DIRSPACER = ',';
my @contentFileChunks = ();

walkDir(
    path => "$currentPath/../css",
    proc => sub {
        my ($file, $deep) = @_;
        return if -d $file;

        if ($file =~ /\.txt$/) {
            my $linkInfo = processFile($file, sub { my ($text, $filename) = @_; htmlTPL($text)});
            push(@contentFileChunks, qq(<a href="$linkInfo->{href}">/$linkInfo->{title}</a> (описание)\n));
        };

        if ($file =~ /\.sqf$/) {
            my @content = parseSqfInlineDocs($file);
            if (scalar @content > 0) {
                my $linkInfo = processFile($file, sub { 
                    my ($text, $filename) = @_; 
                    htmlTPL( htmlTplBlock( join("<hr />", map {escapeHTML($_)} @content), $filename, $text ) );
                });
                push(@contentFileChunks, qq(<a href="$linkInfo->{href}">/$linkInfo->{title}</a> (скрипт)\n));
            };
        };
    }
);

{ 
    local *fhContent;
    open(fhContent, '+>index.html') or die;
    print fhContent htmlContentTPL(join("", map {"<li>$_</li>"} @contentFileChunks));
    close(fhContent);
};

############################################################

sub processFile {
    my $file = shift;
    my $callback = shift;
    my $relFileName = $file;
    $relFileName =~ s/^.*?\.\.\///g;
    my $htmlFileName = $relFileName;
    $htmlFileName =~ s/\/|\\/$DIRSPACER/g;
    $htmlFileName .= ".html";
    {
        local *hndlOutFile;
        open(hndlOutFile, "+>$currentPath/$htmlFileName");
        my $coloredText = getColoredText(qq(-h -imyshorttags "$file"));
        # удалить идентификационнцю строку колорера
        $coloredText =~ s/^Created with colorer-take5 library. Type '\w+'//;
        # удалить избыточные теги раскрашивания
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

    while ( $sqfFileContent =~ m<\n//(\s+)?(?:(?:Функция|function)\s+)?((func(?:\w+|\(\w+\))).*?)\n\s*\3\s*\=\s*{>gcis ) {
        my $padding = $1;
        my $text = $2;
        $text =~ s{\n//$padding?}{\n}g;
        $text =~ s{(//|\s)+$}{}g;
        my $textFunction = $text =~ /[а-яА-Я]/ ? "Функция" : "Function";
        push(@content, "$textFunction $text");
    };

    while ( $sqfFileContent =~ m<\n/\*\n*(\s+)?(?:(?:Функция|function)\s+)?((func(?:\w+|\(\w+\))).*?)\n\*/\s*\3\s*\=\s*{>gcis ) {
        my $padding = $1;
        my $text = $2;
        $text =~ s{\n$padding}{\n}g;
        $text =~ s{\s+$}{}g;
        my $textFunction = $text =~ /[а-яА-Я]/ ? "Функция" : "Function";
        push(@content, "$textFunction $text");
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

    local *FILEIN;
    my $pid = open(FILEIN, "-|", ($value." ".(shift)));
    my $result = join("", map {$_} <FILEIN>);
    close(FILEIN);
    $result;
};


sub walkDir {  # ( path => string, opendir => sub, proc => sub, closedir => sub, sort => sub )

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

        for $filename (
            sort {
                -d $path . '/' . $b cmp -d $path . '/' . $a
            } @dirlist
        ) {
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
    $_[0] =~ s/[<>&"]/{'<','&lt;', '>','&gt;', '&','&amp;', '"','&quot;'}->{$&}/eg;
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

sub htmlTPL {
    qq{<!doctype html>
<html>
<head>
<title></title>
<meta http-equiv="content-type" content="text/html; charset=windows-1251" />
<style type="text/css">
body { margin: auto; }
* {cursor:default}
pre {
padding: 1em 4em;
}
pre.code,
pre.code b,
pre.code i,
pre.code s,
pre.code u,
pre.code tt,
pre.code em,
pre.code var {
text-decoration: none;
font: normal normal 14px/150% Consolas, monospace;
}
pre.code b  {color:#009}
pre.code i  {color:#080}
pre.code s  {color:#BBB; font-style: italic}
pre.code u  {color:#0A0}
pre.code tt {color:#994}
pre.code em {color:#A00}
pre.code var {color:#5E5E5E}

hr { margin: 1em 0 1em 0; border: 1px dashed #ccc; }
#unfoldcode:hover { cursor: hand; color: red }
</style>
</head>
<body>
<pre class="code">@_[0]</pre>
</body>
</html>}
};

sub htmlContentTPL {
qq{<!doctype html>
<html>
<head>
<title></title>
<meta http-equiv="content-type" content="text/html; charset=windows-1251" />
<style type="text/css">
body { margin: auto; padding: 1em 0; width: 45em }
</style>
</head>
<body>
<h1>CSS (auto-documentation)</h1>
<h2>Scripts and help files</h2>
<ul>
@_[0]
</ul>
</body>
</html>}
};
