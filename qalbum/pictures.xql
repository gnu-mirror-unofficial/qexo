(:
declare namespace exif-extractor = "class:com.drew.imaging.exif.ExifExtractor"
declare namespace exif-loader = "class:com.drew.imaging.exif.ExifLoader"
declare namespace ImageInfo = "class:com.drew.imaging.exif.ImageInfo"
:)
declare variable $nl { "&#10;" };

declare function make-img($picture, $scale) {
  <img src="{$picture}" width="{number($picture/@width) * $scale}"
    height="{number($picture/@height) * $scale}"/>
};

declare function make-thumbnail($pic) {
  if ($pic/small-image) then
    make-img($pic/small-image, 1.0)
  else if ($pic/image) then
    make-img($pic/small-image, 0.5)
  else if ($pic/full-image) then
    make-img($pic/full-image, 0.2)
  else
  ( "(missing small-image)", string($pic), ")" )
};

declare function style-link($style) {
  if ($style="full") then "large" else $style
}

declare function make-link($picture-name, $style, $text) {
  <a href="{$picture-name}{style-link($style)}.html">{$text}</a>
};

declare function format-row($row) {
  "&#10;  ", (: emit a newline for readabilty :)
  <table width="90%" class="row"><tr>{
  for $pic in $row return
  <td>
   <table bgcolor="black" cellpadding="0" frame="border"
      border="0" rules="none">
      <tr>
        <td align="center"><a href="{$pic/@id}.html">{
          make-thumbnail($pic)}</a></td>
      </tr>
      { if ($pic/caption) then
      <tr>
        <td  bgcolor="#FFFF99" align="center"><a class="textual"
          href="{$pic/@id}.html">{$pic/caption/node()}</a></td>
      </tr>
      else ()}
    </table>
  </td>
  }</tr></table>
};

(: Process a sequence of <picture> elements, grouping them into
 : rows of at most 3, for the thumbnail page.
 : $prev:  An integer giving the number of <picture>s in
 :   this current sequence that precede those in $pictures.
 : $pictures:  Remaining <picture> elements to process.
 : Returns formatted HTML for the input $pictures.
 :)
declare function make-rows($prev, $pictures) {
  let $count := count($pictures) return
  if ($count = 0) then ()
  else if ($count <= 3) then
    format-row($pictures)
  else if ($count = 4 and $prev = 0) then
    (: A special case:  If there are 4 pictures in a row,
     : then group them as 2 rows of 2 rather than 3 + 1. :)
    (format-row(sublist($pictures, 1, 2)),
     format-row(sublist($pictures, 3, 2)))
  else
     (format-row(sublist($pictures, 1, 3)),
      make-rows($prev+3,sublist($pictures, 4)))
};

(: Process the children of a <group>, grouping thumbnails into rows.
 : $pictures:  Sequence of <picture>s that need to be split into rows.
 : $unseen: sequence of remaining children we have not processed yet.
 :)
declare function find-rows($pictures, $unseen) {
  if (empty($unseen)) then make-rows(0, $pictures)
  else
    let $next := item-at($unseen, 1),
        $rest := sublist($unseen, 2)
    return
      typeswitch ($next)
      case element(row,*) return
        (make-rows(0, $pictures),format-row($next/*),find-rows((), $rest))
      case element(date,*) return (: ignore <date> children here. :)
        (make-rows(0, $pictures),find-rows((), $rest))
      case element(title,*) return (: ignore <title> children here. :)
        (make-rows(0, $pictures),find-rows((), $rest))
      case element(text,*) return (: format <text> as a paragraph. :)
        (make-rows(0, $pictures),<p>{$next/node()}</p>,find-rows((), $rest))
      default return
        find-rows(($pictures,$next), $rest)
};

declare function picture-text($picture) {
  for $text in $picture/text return <p>{$text/node()}</p>
};

declare function make-title($picture, $group) {
  concat(string($group/title), " - ",
         if (empty($picture/caption)) then string($picture/@id)
         else string($picture/caption))
};

declare function make-header($picture, $group) {
  <h2>{if ($picture/caption) then $picture/caption/node()
       else $group/title/node()}</h2>
};

(: Create a 1-row navigation-bar: next, prev etc :)

declare function nav-bar($picture, $name, $prev, $next, $style) {
<table>
  <tr>
    <td><span class="button"><a href="index.html">Index</a></span></td>{
    if ($style="info") then () else ("
    ",<td><span class="button">{make-link($name, "info", "Info")}</span></td>),
    if ($style="large" or $style="full") then () else ("
    ",<td width="200" align="left"><span class="button">{
      make-link($name, "large", "Large image")}</span></td>),
    if ($style="") then () else ("
    ",<td width="200" align="left"><span class="button">{
      make-link($name, "", "Medium image")}</span></td>)}
    <td width="100" align="right">{
      if ($prev) then
        <span class="button">{make-link($prev/@id, $style, " < Previous ")
      }</span> else ()}</td>
    <td width="100" align="left">{
      if ($next) then
        <span class="button">{make-link($next/@id, $style, " Next > ")}</span>
      else ()
    }</td>
  </tr>
</table>
};

declare function get-image-info ($name)
{
(:
<pre>{
  let $info := exif-loader:getImageInfo(java.io.File:new(concat($name,".jpg")))
  for $i in iterator-items(ImageInfo:getTagIterator($info)) return
 ( "
", ImageInfo:getTagName($i),": ", ImageInfo:getDescription($info, $i))
}</pre>
:)
  doc(concat($name,"-info.txt"))
};

declare function raw-jpg-link($image, $description) {
  if (empty($image)) then () else
  <td><span class="button"><a href="{$image}">{$description} ({
    string($image/@width)}x{string($image/@height)})</a></span></td>
};

(: Generate a page picture image with links etc.
 : $picture:  The <picture> node to use.
 : $group:  The enclosing <group>.
 : $name:  The string-value of the picture's id attribute.
 : $preamble: Paragraphs that lead-in to this (group of) pictures.
 : $prev:  The previous <picture> or the empty sequence if there is none.
 : $next:  The next <picture> or the empty sequence if there is none.
 : $date:  The date the picture was taken, as a string, or the empty sequence.
 : $style:  The style and size.
 :   Currently only "full", "large" or "" (medium) or "info".
 :   The "info" style show a thumbnail, plus EXIF information, plus links to
 :   the raw JPGs.  The "full" style is like "large" but auto-resizing.
 :)
declare function picture($picture, $group, $name, $preamble, $prev, $next, $date, $style, $i, $count) {
(: FIXME add documentheader and DO NOT EDIT comment :)
<html>
  <head>
    <meta content="text/html; charset=UTF-8" http-equiv="Content-Type"/>
    <link rel="up" href="index.html" />{
    (: Note how we pre-pend whitespace to properly indent the <link>s. :)
    if (empty($prev)) then ()
    else ("
    ",<link rel="prev" href="{$prev/@id}{style-link($style)}.html" />),
    if (empty($next)) then ()
    else ("
    ",<link rel="next" href="{$next/@id}{style-link($style)}.html" />)}
    <title>{make-title($picture,$group)}</title>
    <style type="text/css">
      a {{ padding: 1 4; text-decoration: none; }}
      td {{ padding-left: 0; border-style: none }}
      span.button {{ border: thin solid; background-color: #FFFF99; }} {
    if ($style!="full") then '
      img { border: thin solid black }'
    else '
      img { position: absolute; bottom: 0px; right: 0px; }
      img { visibility: hidden }
      body { overflow: hidden }
      div#preamble { position: absolute; top: 0px; left: 0px; width: 600px }
      div.preamble-text { background-color: #FFFF99; border: 1px solid black; padding: 0.5em} '}
   </style>
{(  (: (Note what we have to do to add an XQuery comment here!)
     : Next we generate a JavaScript handler, to handle pressing the keys
     : 'n' (or space) and 'p' for navigation.  The indentation of the code
     : isn't "logical", but it makes the JavaScript code look nice. :) )}
    <script language="JavaScript">
      document.onkeypress = handler;
      var hidePreamble = false;
      function handler(e) {{
        var key = e ? e.which : event.keyCode;{
        if (empty($next)) then ()
        else (: if 'n' was pressed, goto $next :)
          concat('
        if (key == 110 || key == 32) { location="',
          string($next/@id), style-link($style), '.html"; return true; }'),
        if (empty($prev)) then ()
        else (: if 'p' was pressed, goto $prev :)
          concat('
        if (key == 112) { location="',
          string($prev/@id), style-link($style), '.html"; return true; }')}
        if (key == 117) {{ location="index.html"; return true; }}
        if (key == 105) {{ location="{$name}info.html"; return true; }}
        if (key == 108) {{ location="{$name}large.html"; return true; }}
        if (key == 109) {{ location="{$name}.html"; return true; }}
	if (key == 104) {{
	  var preamble = document.getElementById("preamble");
	  hidePreamble = !hidePreamble;
	  preamble.style.visibility = hidePreamble ? "hidden" : "visible";
	  return true;
        }}
        return routeEvent(e);
      }}{ if ($style!="full") then () else '
      function LoadSize() {
        image = document.getElementsByTagName("img")[0];
	image.origwidth = image.getAttribute("width");
        image.origheight = image.getAttribute("height");
        ScaleSize();
        image.style.visibility = "visible";
      }
      function ScaleSize() {
        /* Window size calculation from S5 slides.css. by Eric Meyer. */
	var hSize, vSize;
 	if (window.innerHeight) {
		vSize = window.innerHeight;
		hSize = window.innerWidth;
	} else if (document.documentElement.clientHeight) {
		vSize = document.documentElement.clientHeight;
		hSize = document.documentElement.clientWidth;
	} else if (document.body.clientHeight) {
		vSize = document.body.clientHeight;
		hSize = document.body.clientWidth;
	} else {
		vSize = 700;  // assuming 1024x768, minus chrome and such
		hSize = 1024; // these do not account for kiosk mode or Opera Show
	}
        var image = document.getElementsByTagName("img")[0];
        var wscale = hSize /  image.origwidth;
        var hscale = vSize / image.origheight;
        var scale = Math.min(wscale, hscale);
        image.style.width = scale * image.origwidth;
        image.style.height = scale * image.origheight;
      }'}
    </script>
  </head>
{
  element body {
    attribute bgcolor {"#00DDDD"},
    if ($style="full") then
      (attribute onload {"javascript:LoadSize();"},
      attribute onresize {"javascript:ScaleSize();"})
    else
    above-picture($picture, $group, $name, $preamble, $prev, $next, $date, $style, $i, $count),
  let $full-image := $picture/full-image,
      $image := $picture/image
  return
  if ($style = "info") then (
    <table><tr>
      <td style="padding: 20 20 20 10">{make-thumbnail($picture)} </td>
      <td>{get-image-info($name)}</td>
    </tr></table>,"
", (: FIXME use $nl :)
    <table><tr><td>Plain JPEG images:</td>
    {raw-jpg-link($picture/full-image, "Original")}
    {raw-jpg-link($picture/image,
    if ($full-image) then "Scaled" else "Original")}
    {raw-jpg-link($picture/small-image, "Thumbnail")}
    </tr></table>,"
", (: FIXME use $nl :)
    let $outtakes := $picture/outtake return
      if (empty($outtakes)) then () else
        <table><tr><td>Outtakes:</td>
          {for $outtake in $outtakes return
             let $outtext := $outtake/node() return
            <td><span class="button"><a href="{string($outtake/@img)}">{if (empty($outtext)) then "picture" else $outtext}</a></span></td>}
        </tr></table>
  )
  else if (($style="large" or $style="full") and $full-image) then
    make-img($full-image, 1)
  else if ($style="full" and $image) then
    make-img($image, 1)
  else if ($style="large" and $image
           and number($image/@width) <= 640
           and number($image/@height) <= 640) then
    make-img($image, 2)
  else if ($full-image) then
    make-img($full-image, 0.5)
  else
    make-img($image, 1)
 },
 (: In "full" style, we need to draw the header etc *after* the image. :)
 if ($style!="full") then () else
    above-picture($picture, $group, $name, $preamble, $prev, $next, $date, $style, $i, $count)
 }
</html>,$nl
};

declare function above-picture($picture, $group, $name, $preamble, $prev, $next, $date, $style, $i, $count) {
<div id="preamble">
{ (:if ($style="full") then () else:)
  nav-bar($picture, $name, $prev, $next, $style)}
<div class="preamble-text">
<p>{if ($i=$count) then "Last" else concat("Number ", $i)} of {$count}.  {
  if (empty($date)) then () else concat("Date taken: ",string($date),"."),
  if ($style="full") then <i> [Type <code>h</code> to hide.]</i> else () }</p>
{ $preamble }
{ make-header($picture, $group)}
{ picture-text($picture)}
</div>
</div>
};

declare function make-group-page($group) {
<html>
  <head>
    {$group/title}
    <link rel="up" href="../index.html" />
    <link rel="top" href="../../index.html" />
    <style type="text/css">
      a.textual {{ text-decoration: none }}
      img {{ border: 0 }}
      table.row {{ padding: 10px }}
    </style>
    <script language="JavaScript">
      document.onkeypress = handler;
      function handler(e) {{
        var key = navigator.appName == 'Netscape' ? e.which
          : window.event.keyCode;
        if (key == 117) {{ location="../index.html"; return true; }}
        return routeEvent(e); }}
    </script>
  </head>
  <body bgcolor="#00AAAA">
    <h2>{$group/title/node()}</h2>
{   find-rows((), $group/*)}
  </body>
</html>
};

(: For a given $style, recurse over pictures to link.
 : $group: the <group> document element.
 : $pictures: all the <picture> elements that a descendents of $group.
 : $i: the index in $pictures of the next <picture> to process.
 : $count: the number of <picture> elements in $pictures.
 : $style: the current style
 : $texts: <text> nodes seen so far that are not in a <picture>.
 : $unseen: the modes (<picture>, <row>, <text>) to process for this call.
 :)
declare function loop-pictures($group, $pictures, $i, $count, $style, $texts, $unseen) {
  if (empty($unseen)) then ()
  else
    let $cur := item-at($unseen, 1),
        $rest := sublist($unseen, 2)
    return
      typeswitch ($cur)
      case element(row,*) return (
	 loop-pictures($group, $pictures, $i, $count, $style, $texts, $cur/*),
         loop-pictures($group, $pictures, $i+count($cur//picture),
           $count, $style, (), $rest))
      case element(text,*) return
        loop-pictures($group, $pictures, $i, $count, $style,
                      ($texts,<p>{$cur/node()}</p>), $rest)
      case element(picture,*) return
        let $prev := if ($i > 1) then item-at($pictures, $i - 1) else (),
            $next := if ($i < $count) then item-at($pictures, $i + 1) else (),
            $date := if ($cur/date) then $cur/date else $group/date,
	    $name := string($cur/@id)
        return
        (write-to(picture($cur,  $group, $name,
		    $texts, $prev, $next, $date, $style, $i, $count),
                  concat($name, style-link($style), ".html")),
         loop-pictures($group, $pictures, $i+1, $count, $style, (),  $rest))
      default return
         loop-pictures($group, $pictures, $i, $count, $style, $texts,  $rest)
};

let $group := doc("index.xml")/group,
    $group-name := $group/title,
    $pictures := $group//picture,
    $count := count($pictures)
  return (
    write-to(make-group-page($group), "index.html"),
    for $style in ("", "info", "full")
    return
    loop-pictures($group, $pictures, 1, $count, $style, (), $group/*))
