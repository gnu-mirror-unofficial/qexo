define function listing($url) {
  (: doc($url) replaced document($url) in the May'03 spec. :)
  <pre> { doc($url) } </pre>
}
listing("data.txt"), ""

