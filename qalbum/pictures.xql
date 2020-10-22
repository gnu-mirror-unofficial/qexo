declare namespace PictureInfo = "class:qalbum.PictureInfo";
declare namespace SelectFiles = "class:qalbum.SelectFiles";
declare namespace Path = "class:gnu.kawa.io.Path";
declare boundary-space preserve;
declare variable $libdir external;
declare variable $nl := "&#10;";
declare variable $nbsp := "&#160;";
declare variable $pwd := Path:currentPath();
declare variable $bgcolor := "#60ECEC";
declare variable $defaultSize := "large";

declare function local:dont-skip($picinfo) {
  PictureInfo:dontSkip($picinfo)
 (: let $rating := PictureInfo:getRating($picinfo)
  return $rating eq 0 or $rating gt 2:)
};

declare function local:make-img($class, $picinfo) {
  let $image-name := PictureInfo:getScaledFile($picinfo, $class) return
  <img class="{$class}" src="{$image-name}"
    width="{PictureInfo:getScaledWidth($picinfo, $class)}"
    height="{PictureInfo:getScaledHeight($picinfo, $class)}"/>
};

declare function local:make-main-img($picinfo, $scale as xs:double, $class) {
  let $image-name := PictureInfo:getScaledFile($picinfo, $class) return
  <div><img class="main" id="main-image" src="{$image-name}"
    width="{PictureInfo:getWidthFor($picinfo, $image-name) * $scale}"
    height="{PictureInfo:getHeightFor($picinfo, $image-name) * $scale}"/></div>
};

declare function local:make-thumbnail($picinfo) {
  local:make-img("thumb", $picinfo)
};

declare function local:style-link($style) {
  $style
  (:if ($style="full") then "large" else $style:)
};

declare function local:make-style-link($picture-name, $style, $text) {
  <span class="button" style-button="{if ($style="") then $defaultSize else $style}"><a href="{$picture-name}{local:style-link($style)}.html">{$text}</a></span>
};

declare function local:get-caption($picinfo) {
  PictureInfo:getCaption($picinfo)
};

declare function local:get-datetime($picinfo, $date) {
  if (empty($date)) then (
    let $dt := PictureInfo:getDateTime($picinfo)
    return concat(translate(substring($dt, 1, 11), ":", "/"),
                  substring($dt, 12, 5))
  )
  else $date
};

declare function local:format-group-image($pinfo) {
  let $label := PictureInfo:getLabel($pinfo) return
  <span id="{$label}" class="piclink">
      <div><a fixup="style" href="{$label}.html">{
          local:make-thumbnail($pinfo)}</a></div>{
      let $caption := local:get-caption($pinfo) return
      if ($caption) then ("
      ",<div class="caption">{$caption}</div>)
      else ()}
  </span>
  (:
  <span id="{$label}" class="piclink">
   <table>
      <tr>
        <td align="center"><a fixup="style" href="{$label}.html">{
          local:make-thumbnail($pinfo)}</a></td>
      </tr>{
      let $caption := local:get-caption($pinfo) return
      if ($caption) then ("
      ",<tr><td align="center" class="caption">{$caption}</td></tr>)
      else ()}
    </table>
  </span>
  :)
};

declare function local:picture-text($picture) {
  for $text in $picture/text return <p><span>{$text/node()}</span></p>
};

declare function local:make-title($picinfo, $group) {
  let $caption := local:get-caption($picinfo) return
  concat(string($group/title), " - ",
         if ($caption) then string($caption) else  PictureInfo:getLabel($picinfo))
};

(: Create a 1-row navigation-bar: next, prev etc :)

declare function local:nav-bar($name, $prevId, $nextId, $style) {
  <div pstyle="{$style}"><span id="prev-button" class="button">{if ($prevId) then
  <div><a id="prev-link" href="{$prevId}{local:style-link($style)}.html"><div>&lt;-<br/>Previous</div></a></div>
  else ()}</span>{(
    )}<span style="display: inline-block; width: 80%"><span id="up-button" class="button"><a class="button" id="up-link" href="index.html">Up to index</a></span>{
  if ($style="info") then () else ("
  ",local:make-style-link($name, "info", "Image-info")),
  if ($style="large" or $style="full" or $style="") then () else ("
  ",local:make-style-link($name, "", "Higher resolution")),
  if ($style="medium") then () else ("
  ",local:make-style-link($name, "medium", "Lower resolution"))}
  <span id='slider-button' class='button'><a id='slider-link' href='slider.html#{$name}{$style}'>Show Slider</a></span>
{ if ($style="info") then () else (
       <span id="zoom-buttons" class='button'><a id='zoom-in-button' href='javascript:ZoomIn()'>Zoom{$nbsp}in:</a><input type='text' size='4' value='1.0' id='zoom-input-field'></input><a id='zoom-out-button' href='javascript:ZoomOut()'>out</a></span>, "
")
 }<span class="button"><a href="{$libdir}/help.html">Help</a></span>
</span
  ><span id="next-button" class="button">{if ($nextId) then
  <div><a id="next-link" href="{$nextId}{local:style-link($style)}.html"><div>-&gt;<br/>Next</div></a></div>
  else ()}</span></div>
};

declare function local:raw-jpg-link($class, $description, $picinfo) {
  if (PictureInfo:getScaledExists($picinfo, $class)) then
   let $image := PictureInfo:getScaledFile($picinfo, $class) return
  <td><span class="button"><a href="{$image}">{$description} {PictureInfo:getSizeDescription($picinfo, $image)}</a></span></td>
  else ()
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
declare function local:picture($picinfo, $group, $name, $preamble, $text, $prevId, $nextId, $date, $style, $i, $count, $outtakes) {
(: FIXME add documentheader and DO NOT EDIT comment :)
<html>
  <head>
    <meta content="text/html; charset=UTF-8" http-equiv="Content-Type"/>
    <link rel="up" href="index.html" />{
    (: Note how we pre-pend whitespace to properly indent the <link>s. :)
    if ($prevId)
    then ("
    ",<link rel="prev" href="{$prevId}{local:style-link($style)}.html" />)
    else (),
    if ($nextId)
    then ("
    ",<link rel="next" href="{$nextId}{local:style-link($style)}.html" />)
    else ()}
    <link rel="stylesheet" title="QAlbum style" href="../../lib/qalbum.css"/>
    <title>{local:make-title($picinfo,$group)}</title>
    <!--Used by JavaScript-->
    <style type="text/css">
    </style>
    <meta name="viewport" content="width=device-width, height=device-height, initial-scale=1.0, maximum-scale=1.0"/>
{
(:    <meta name="viewport" content="target-densitydpi=device-dpi" /><!--For Android--> :)
(
    (: (Note what we have to do to add an XQuery comment here!)
     : Next we generate a JavaScript handler, to handle pressing the keys
     : 'n' (or space) and 'p' for navigation.  The indentation of the code
     : isn't "logical", but it makes the JavaScript code look nice. :) )}
    <script type="text/javascript">
      var thisId = "{$name}";
      var nextId = "{$nextId}";
      var prevId = "{$prevId}";
      var libdir = "{$libdir}";
      var hash = location.hash;
      var style_link = "{local:style-link($style)}";
      var uphash = {if ($style="info") then '"#info"'
                    else if ($style="medium") then 'location.hash ? location.hash : "#medium"'
                    else 'location.hash?location.hash:top.slider?"#slider":""'};
    </script>
    <script type="text/javascript" src="{$libdir}/picture.js">{((:Following space needed to force output of closing tag:))} </script>
  </head>
{
  element body {
    attribute onload {"javascript:OnLoad();"},
    attribute onresize {"javascript:ScaledResize();"},
    local:above-picture($picinfo, $group, $name, $text, $preamble, $prevId, $nextId, local:get-datetime($picinfo, $date), $style, $i, $count),
  if ($style = "info") then (
    <table><tr>
      <td style="padding: 20 20 20 10">{local:make-thumbnail($picinfo)} </td>
      <td><pre>
{PictureInfo:getImageDescription($picinfo)}
</pre></td>
    </tr></table>,"
", (: FIXME use $nl :)
    <table><tr><td>Plain JPEG images:</td>
    {local:raw-jpg-link("original", "Original", $picinfo)}
    {if (PictureInfo:getScaledExists($picinfo, "medium")
         and PictureInfo:getScaledExists($picinfo, "original")) then
     let $mimage := PictureInfo:getScaledFile($picinfo, "medium"),
         $oimage := PictureInfo:getScaledFile($picinfo, "original"),
         $mfile := string($mimage),
         $ofile := string($oimage)
     where $mfile ne $ofile
     return
    <td><span class="button"><a href="{$mfile}">Scaled {PictureInfo:getSizeDescription($picinfo, $mimage)}</a></span></td>
    else ()}
    {local:raw-jpg-link("thumb", "Thumbnail", $picinfo)}
    </tr></table>,"
", (: FIXME use $nl :)
      if (empty($outtakes)) then () else
        <table><tr><td>Outtakes:</td>
          {for $outtake in $outtakes return
             let $outtext := $outtake/node() return
            <td><span class="button"><a href="{string($outtake/@img)}">{if (empty($outtext)) then "picture" else $outtext}</a></span></td>}
        </tr></table>
  )
  else if (($style="large" or $style="full" or $style="")
           and PictureInfo:getScaledExists($picinfo, "large")) then
    local:make-main-img($picinfo, 1e0, "l")
  else if (not(PictureInfo:getScaledExists($picinfo, "medium"))) then
    local:make-main-img($picinfo, 0.5e0, "l")
  else if ($style="full") then
    local:make-main-img($picinfo, 1e0, "m")
  else if ($style="large"
           and (let $image-name := PictureInfo:getScaledFile($picinfo, "medium")
                return
                 PictureInfo:getWidthFor($picinfo, $image-name) <= 640 and
                 PictureInfo:getHeightFor($picinfo, $image-name) <= 640)) then
      local:make-main-img($picinfo, 2e0, "m")
  else
      local:make-main-img($picinfo, 1e0, "m")
 }
 }
</html>,$nl
};

declare function local:above-picture($picinfo, $group, $name, $text, $preamble, $prevId, $nextId, $date, $style, $i, $count) {
<div id="preamble">
{ local:nav-bar($name, $prevId, $nextId, $style)}
<div class="preamble-text">
{ $preamble }
<p><span class="preamble-title"><b>{let $caption := local:get-caption($picinfo) return
  if ($caption) then $caption else $group/title/node()}</b></span>
<span class="preamble-num-date">{
  if (empty($date)) then () else concat("&#xA0;&#xA0;",string($date),".")}
  {if ($i=$count) then "Last" else concat("&#xA0;", $i)}&#xA0;of&#xA0;{$count}</span>
</p>
{""(: if ($style="full") then <script type="text/javascript">if (scaled) document.write(" <p><span>[Type <code>h</code> to hide.]</span></p>")</script> else ():) }
{ $text }
</div>
</div>
};

declare function local:make-slider-page($group, $picinfos) {
let $first := PictureInfo:getLabel(item-at($picinfos,1)) return
<html>
  <head>
    {$group/title}
    <link rel="up" href="../index.html" />
    <link rel="top" href="../../index.html" />
    <script type="text/javascript">
      var sliderBgcolor = "{$bgcolor}";
      function loadFrames() {{
        var hash=top.location.hash;
        var main=top.main;
        top.slider.sliderInit(hash ? hash.substring(1) : "{$first}");
      }}
    </script>
  </head>
  <frameset cols="280,*" onload="top.loadFrames()">
    <frame name="slider" src="index.html" />
    <frame name="main" src="{$first}.html" />
  </frameset>
</html>
};

declare function local:group-page-helper($nodes, $i, $n,
                                                $picinfos, $p) {
  if ($i > $n) then ()
  else
  let $item := item-at($nodes, $i) return
    typeswitch ($item)
      case element(text) return
        (<tr><td><p>{$item/node()}</p></td></tr>,
          local:group-page-helper($nodes, $i+1, $n, $picinfos, $p))
      case element(row) return (: deprecated :)
        let $pictures := $item/picture
        let $npictures := count($pictures) return
          (local:group-page-helper($pictures, 1, $npictures,
                                          $picinfos, $p),
           local:group-page-helper($nodes, $i+1, $n,
                                          $picinfos, $p+$npictures))
      case element(select) return
        if ($p <= count($picinfos) and $item is PictureInfo:getKey(item-at($picinfos, $p)))
        then (
          local:format-group-image(item-at($picinfos, $p)),
          local:group-page-helper($nodes, $i, $n, $picinfos, $p+1))
        else
          local:group-page-helper($nodes, $i+1, $n, $picinfos, $p)
      case element(picture) return
      if ($p > count($picinfos) or fn:not($item is PictureInfo:getKey(item-at($picinfos, $p))))
      then
        local:group-page-helper($nodes, $i+1, $n, $picinfos, $p)
      else (
      local:format-group-image(item-at($picinfos, $p)),
      local:group-page-helper($nodes, $i+1, $n, $picinfos, $p+1))
  default return
    local:group-page-helper($nodes, $i+1, $n, $picinfos, $p)
};

declare function local:make-group-page($group, $picinfos) {
<html>
  <head>
    {$group/title}
    <link rel="up" href="../index.html" />
    <link rel="help" href="{$libdir}/help.html" />
    <link rel="top" href="../../index.html" />
    <link rel="stylesheet" title="QAlbum style" href="../../lib/qalbum.css"/>
    <script type="text/javascript" src="{$libdir}/group.js"> </script>
  </head>
  <body bgcolor="{$bgcolor}" default-style="{$defaultSize}" onload="javascript:fixLinks();">
  <div id="header">
  <p id="group-buttons">
    <a href="{$libdir}/help.html">Help</a>
    <a href="../index.html">Up</a>
    <a href="slider.html">Slider</a>
    </p>
    <h2>{$group/title/node()}</h2>
  </div>
{ let $nodes := $group/* return
    local:group-page-helper($nodes, 1, count($nodes), $picinfos, 1)
}
  </body>
</html>
};

(: For a given $style, recurse over pictures to link.
 : $group: the <group> document element.
 : $i: the index in $picinfos of the next picture to process.
 : $count: the count of $picinfos
 : $style: the current style
 : $texts: <text> nodes seen so far that are not in a <picture>.
 : $unseen: the nodes (<picture>, <row>, <text>) to process for this call.
 :)
declare function local:loop-pictures($group, $date, $i, $count, $style, $texts, $unseen, $picinfos) {
  if (empty($unseen)) then ()
  else
    let $cur := item-at($unseen, 1),
        $rest := subsequence($unseen, 2)
    return
      typeswitch ($cur)
      case element(row) return (
	 local:loop-pictures($group, $date, $i, $count, $style, $texts, $cur/*, $picinfos),
         local:loop-pictures($group, $date, $i+count($cur//picture),
           $count, $style, (), $rest, $picinfos))
      case element(text) return
        local:loop-pictures($group, $date, $i, $count, $style,
                      ($texts,<p><span>{$cur/node()}</span></p>), $rest, $picinfos)
      case element(date) return
        local:loop-pictures($group, $cur, $i, $count, $style,
                      $texts, $rest, $picinfos)
      case element(select) return
      if ($i > $count or fn:not($cur is PictureInfo:getKey(item-at($picinfos, $i))))
      then
        local:loop-pictures($group, $date, $i, $count, $style,
                      (), $rest, $picinfos)
      else
        let $picinfo := item-at($picinfos, $i),
            $prevId := if ($i > 1) then PictureInfo:getLabel(item-at($picinfos, $i - 1)) else "",
            $nextId := if ($i < $count) then PictureInfo:getLabel(item-at($picinfos, $i + 1)) else "",
	    $name := PictureInfo:getLabel($picinfo)
        return (
        write-to-if-changed(local:picture($picinfo, $group, $name,
		    $texts, local:picture-text($cur),
                    $prevId, $nextId, $date, $style, $i, $count, ()),
                  resolve-uri(concat($name, local:style-link($style), ".html"), $pwd)),
        local:loop-pictures($group, $date, $i+1, $count, $style,
                      (), $unseen, $picinfos))
      case element(picture) return
        if ($i > $count or fn:not($cur is PictureInfo:getKey(item-at($picinfos, $i))))
      then
        local:loop-pictures($group, $date, $i, $count, $style, (), $rest, $picinfos)
      else
        let $prevId := if ($i > 1) then PictureInfo:getLabel(item-at($picinfos, $i - 1)) else "",
            $nextId := if ($i < $count) then PictureInfo:getLabel(item-at($picinfos, $i + 1)) else "",
            $pdate := if ($cur/date) then $cur/date else $date,
            $picinfo := item-at($picinfos, $i),
	    $name := PictureInfo:getLabel($picinfo)
        return (
        write-to-if-changed(local:picture($picinfo, $group, $name,
		    $texts, local:picture-text($cur),
                    $prevId, $nextId, $pdate, $style, $i, $count,
                    $cur/outtake),
                  resolve-uri(concat($name, local:style-link($style), ".html"), $pwd)),
         local:loop-pictures($group, $date, $i+1, $count, $style, (),  $rest, $picinfos))
      default return
         local:loop-pictures($group, $date, $i, $count, $style, $texts, $rest, $picinfos)
};

declare function local:get-pictures($nodes) {
  for $cur in $nodes return
  typeswitch ($cur)
      case element(row) return local:get-pictures($cur/*)
      case element(picture) return
        let $full-image := $cur/full-image,
            $image := if ($full-image) then $full-image else $cur/image,
            $pinfo := PictureInfo:getImages($cur, string($cur/@id),
                                     string($cur/original/@rotated),
                                     string($image), string($cur/caption))
        where local:dont-skip($pinfo)
        return $pinfo
      case element(select) return
        SelectFiles:selectFiles(string($cur/@path), $cur)
      default return ()
};

let $index-file-uri := resolve-uri("index.xml", $pwd),
    $group := doc($index-file-uri)/group,
    $group-name := $group/title,
    $picinfos := local:get-pictures($group/*),
    $count := count($picinfos)
  return (
write-to(for $g in $group/* return ("[",$g, "]
"), "file:/tmp/groups"),
    write-to-if-changed(local:make-slider-page($group, $picinfos), resolve-uri("slider.html", $pwd)),
    write-to-if-changed(local:make-group-page($group, $picinfos), resolve-uri("index.html", $pwd)),
    for $style in ("", "medium", "info")
    return
    local:loop-pictures($group, $group/date[1], 1, $count, $style, (), $group/*, $picinfos)
)
