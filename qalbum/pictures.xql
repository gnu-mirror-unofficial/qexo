{--
declare namespace exif-extractor = "class:com.drew.imaging.exif.ExifExtractor"
declare namespace exif-loader = "class:com.drew.imaging.exif.ExifLoader"
declare namespace ImageInfo = "class:com.drew.imaging.exif.ImageInfo"
--}

define function make-img($picture, $scale) {
  <img border="1" src="{$picture}" width="{number($picture/@width) * $scale}"
    height="{number($picture/@height) * $scale}" />
}

define function make-thumbnail($pic) {
  if ($pic/small-image) then
    make-img($pic/small-image, 1.0)
  else if ($pic/image) then
    make-img($pic/small-image, 0.5)
  else if ($pic/full-image) then
    make-img($pic/full-image, 0.2)
  else
  ( "(missing small-image)", string($pic), ")" )
}

define function make-link($picture-name, $style, $text) {
  <a href="{$picture-name}{$style}.html">{$text}</a>
}

define function format-row($row) {
  {-- emit a newline for readabilty --} "
",<table width="90%" class="row"><tr>{
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
}

{-- Process a sequence of <picture> elements, grouping them into
 -- rows of at most 3, for the thumbnail page.
 -- $prev:  An integer giving the number of <pictures> in
 --   this current sequence that precede those in $pictures.
 -- $pictures:  Remaining <picture> elements to processes.
 -- Returns formatted HTML for the input $pictures.
 --}
define function make-rows($prev, $pictures) {
  let $count := count($pictures) return
  if ($count = 0) then ()
  {-- A special case:  If there are 4 pictures in a row, then group them
   -- as 2 rows of 2 rather than 3 + 1. --}
  else if ($count = 4 and $prev = 0) then
     (format-row(sublist($pictures, 1,2)),
      format-row(sublist($pictures, 3,2)))
  else if ($count > 3) then
     (format-row(sublist($pictures, 1,3)),
       make-rows($prev+3,sublist($pictures,4)))
  else format-row($pictures)
}

{-- Process the children of a <group>, grouping thumbnails into rows.
 -- $pictures:  Sequence of <picture>s that need to be split into rows.
 -- $unseen: sequence of remaining children we have not processed yet.
 --}
define function find-rows($pictures, $unseen) {
  if (empty($unseen)) then make-rows(0, $pictures)
  else
    let $next := item-at($unseen, 1),
        $rest := sublist($unseen, 2)
    return
      typeswitch ($next)
      case element row return
        (make-rows(0, $pictures),format-row($next/*),find-rows((), $rest))
      case element date return {-- ignore <date> children here. --}
        (make-rows(0, $pictures),find-rows((), $rest))
      case element title return {-- ignore <title> children here. --}
        (make-rows(0, $pictures),find-rows((), $rest))
      case element text return {-- format <text> as a paragraph. --}
        (make-rows(0, $pictures),<p>{$next/node()}</p>,find-rows((), $rest))
      default return
        find-rows(($pictures,$next), $rest)
}

define function picture-text($picture) {
  for $text in $picture/text return <p>{$text/node()}</p>
}

define function make-title($picture, $group) {
  concat(string($group/title), " - ",
         if (empty($picture/caption)) then string($picture/@id)
         else string($picture/caption))
}

define function make-header($picture, $group) {
  <h2>{if ($picture/caption) then $picture/caption/node()
       else $group/title/node()}</h2>
}

{-- Create a 1-row navigation-bar: next, prev etc --}

define function nav-bar($picture, $name, $prev, $next, $style) {
<table>
  <tr>
    <td><span class="button"><a href="index.html">Index</a></span></td>{
    if ($style="info") then () else ("
    ",<td><span class="button">{make-link($name, "info", "Info")}</span></td>),
    if ($style="large") then () else ("
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
}

define function get-image-info ($name)
{
{--
<pre>{
  let $info := exif-loader:getImageInfo(java.io.File:new(concat($name,".jpg")))
  for $i in iterator-items(ImageInfo:getTagIterator($info)) return
 ( "
", ImageInfo:getTagName($i),": ", ImageInfo:getDescription($info, $i))
}</pre>
--}
  document(concat($name,"-info.txt"))
}

define function raw-jpg-link($image, $description) {
  if (empty($image)) then () else
  <td><span class="button"><a href="{$image}">{$description} ({
    string($image/@width)}x{string($image/@height)})</a></span></td>
}

{-- Generate a page picture image with links etc.
 -- $picture:  The <picture> node to use.
 -- $group:  The enclosing <group>.
 -- $name:  The string-value of the picture's id attribute.
 -- $preamble: Paragraphs that lead-in to this (gorup of) pictures.
 -- $prev:  The previous <picture> or the empty sequence there is none.
 -- $next:  The next <picture> or the empty sequence there is none.
 -- $date:  The date the picture was taken, as a string, or the empty sequence.
 -- $style:  The style and size,  Currently only "large" or "" (medium)
 --   or "info".  The "info" style show a thumbnail, plus EXIF information,
 --   plus links to the raw JPGs.
 --}
define function picture($picture, $group, $name, $preamble, $prev, $next, $date, $style) {
{-- FIXME add documentheader and DO NOT EDIT comment --}
<html>
  <head>
    <meta content="text/html; charset=UTF-8" http-equiv="Content-Type"/>
    <link rel="up"  href="index.html" />{
    {-- Note how we pre-pend whitespace to properly indent the <link>s. --}
    if (empty($prev)) then ()
    else ("
    ",<link rel="prev" href="{$prev/@id}{$style}.html" />),
    if (empty($next)) then ()
    else ("
    ",<link rel="next" href="{$next/@id}{$style}.html" />)}
    <title>{make-title($picture,$group)}</title>
    <style type="text/css">
      a {{ padding: 1 4; text-decoration: none; }}
      td {{ padding-left: 0; border-style: none }}
      span.button {{ border-width: thin; background-color: #FFFF99;
      border-style: solid }}
    </style>{( {-- (Note what we have to do to add an XQuery comment here!)
     -- Next we generate a JavaScript handler, to handle pressing the
     -- keys 'n' and 'p' for navigation.  The indentation of the code
     -- isn't "logical", but it makes the JavaScript code look ok. --} )}
    <script language="JavaScript">
      document.onkeypress = handler;
      function handler(e) {{
        var key = navigator.appName == 'Netscape' ? e.which
          : window.event.keyCode;{
        if (empty($next)) then ()
        else {-- if 'n' was pressed, goto $next --}
          concat('
        if (key == 110) { location="',
          string($next/@id), $style, '.html"; return true; }'),
        if (empty($prev)) then ()
        else {-- if 'p' was pressed, goto $prev --}
          concat('
        if (key == 112) { location="',
          string($prev/@id), $style, '.html"; return true; }')}
        return routeEvent(e); }}
    </script>
  </head>
  <body bgcolor="#00DDDD">
{ nav-bar($picture, $name, $prev, $next, $style)}
{ $preamble }
{ make-header($picture, $group)}
{ picture-text($picture)}
{ if (empty($date)) then () else <p>Date taken: {$date}.</p>}
{ let $full-image := $picture/full-image,
      $image := $picture/image
  return
  if ($style = "info") then (
    <table><tr>
      <td style="padding: 20 20 20 10">{make-thumbnail($picture)} </td>
      <td>{get-image-info($name)}</td>
    </tr></table>,
    <table><tr><td>Plain JPEG images:</td>
    {raw-jpg-link($picture/full-image, "Original")}
    {raw-jpg-link($picture/image,
    if ($full-image) then "Scaled" else "Original")}
    {raw-jpg-link($picture/small-image, "Thumbnail")}
    </tr></table>
  )
  else if ($style="large" and $full-image) then
    make-img($full-image, 1)
  else if ($style="large" and $image
           and number($image/@width) <= 640
           and number($image/@height) <= 640) then
    make-img($image, 2)
  else if ($full-image) then
    make-img($full-image, 0.5)
  else
    make-img($image, 1)
  }
  </body>
</html>
}

define function make-group-page($group) {
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
  </head>
  <body bgcolor="#00AAAA">
    <h2>{$group/title/node()}</h2>
{   find-rows((), $group/*)}
  </body>
</html>
}

define function loop-pictures($group, $pictures, $i, $count, $style, $texts, $unseen) {
  if (empty($unseen)) then ()
  else
    let $cur := item-at($unseen, 1),
        $rest := sublist($unseen, 2)
    return
      typeswitch ($cur)
      case element row return
        (loop-pictures($group, $pictures, $i, $count, $style, $texts, $cur/*),
         loop-pictures($group, $pictures, $i, $count, $style, (), $rest))
      case element text return
        loop-pictures($group, $pictures, $i, $count, $style,
                      ($texts,<p>{$cur/node()}</p>), $rest)
      case element picture return
        let $prev := if ($i > 1) then item-at($pictures, $i - 1) else (),
            $next := if ($i < $count) then item-at($pictures, $i + 1) else (),
            $date := if ($cur/date) then $cur/date else $group/date,
	    $name := string($cur/@id)
        return
        (write-to(picture($cur,  $group, $name,
		    $texts, $prev, $next, $date, $style),
                  concat($name, $style, ".html")),
         loop-pictures($group, $pictures, $i+1, $count, $style, (),  $rest))
      default return
         loop-pictures($group, $pictures, $i, $count, $style, $texts,  $rest)
}

let $group := document("index.xml")/group,
    $group-name := $group/title,
    $pictures := $group//picture,
    $count := count($pictures)
  return (
    write-to(make-group-page($group), "index.html"),
    for $style in ("", "info", "large")
    return
    loop-pictures($group, $pictures, 1, $count, $style, (), $group/*))
