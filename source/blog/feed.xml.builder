xml.instruct!
xml.feed 'xmlns' => 'http://www.w3.org/2005/Atom' do
  xml.title 'ROM Blog'
  xml.subtitle 'News from the ROM team and more'
  xml.id 'http://rom-rb.org/blog/'
  xml.link 'href' => config.site_url
  xml.link 'href' => "#{config.site_url}/feed.xml", 'rel' => 'self'
  xml.updated blog.articles.first.date.to_time.iso8601
  xml.author { xml.name 'ROM team' }

  blog.articles[0..5].each do |article|
    xml.entry do
      xml.title article.title
      xml.link 'rel' => 'alternate', 'href' => article_url(article)
      xml.id article_url(article)
      xml.published article.date.to_time.iso8601
      xml.updated article.date.to_time.iso8601
      xml.author { xml.name article.data['author'] }
      xml.content('type' => 'html') { xml.cdata!(article.body) }
    end
  end
end
