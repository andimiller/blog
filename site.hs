--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll
import           Hakyll.Core.Compiler (unsafeCompiler)
import           Hakyll.Web.Sass (sassCompiler)
import           Hakyll.Web.Tags (buildTags, tagsRules)
import qualified Text.Pandoc.Filter.Plot as Plot (plotFilter, defaultConfiguration)
import           Text.Pandoc.Definition (Pandoc, Format)
import           Data.Time.Format (formatTime, defaultTimeLocale)
import           Data.Time.Clock (getCurrentTime)
--------------------------------------------------------------------------------


main :: IO ()
main = hakyll $ do
    -- build tag list
    tags <- buildTags "posts/*" (fromCapture "tags/*.html")

    tagsRules tags $ \tag pattern -> do
        let title = "Posts tagged '" ++ tag ++ "'"
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll pattern
            let ctx = constField "title" title
                      `mappend` listField "posts" (postCtxWithTags tags) (return posts)
                      `mappend` rootCtx

            makeItem ""
                >>= loadAndApplyTemplate "templates/tag.html" ctx
                >>= loadAndApplyTemplate "templates/default.html" ctx
                >>= relativizeUrls

    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "plots/*.png" $ do
        route   idRoute
        compile copyFileCompiler

    match "cv.pdf" $ do
        route   idRoute
        compile copyFileCompiler

    match "talks/*.html" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*.scss" $ do
        route $ setExtension "css"
        let compressCssItem = fmap compressCss
        compile (compressCssItem <$> sassCompiler)

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "cv.md" $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" rootCtx 
            >>= relativizeUrls

    match "posts/*" $ do
        route $ setExtension "html"
        compile $ customPandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    (postCtxWithTags tags)
            >>= loadAndApplyTemplate "templates/default.html" (postCtxWithTags tags)
            >>= relativizeUrls

    create ["posts.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Posts"               `mappend`
                    rootCtx 

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls

    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    rootCtx 

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler

    create ["sitemap.xml"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            now <- unsafeCompiler getCurrentTime
            let today = formatTime defaultTimeLocale "%0Y-%m-%d" now
            singlePages <- loadAll (fromList ["index.html", "posts.html", "cv.html"])
            let pages = posts <> singlePages
                sitemapCtx = listField "pages" (postCtx <> constField "today" today) (return pages) `mappend` constField "today" today `mappend` rootCtx
            makeItem ""
                >>= loadAndApplyTemplate "templates/sitemap.xml" sitemapCtx

    create ["robots.txt"] $ do
         route idRoute
         compile $ do
              makeItem ""
                  >>= loadAndApplyTemplate "templates/robots.txt" rootCtx
--------------------------------------------------------------------------------
customTransform :: Pandoc -> Compiler Pandoc
customTransform p = unsafeCompiler (Plot.plotFilter Plot.defaultConfiguration (Just "SVG") p)
--------------------------------------------------------------------------------
customPandocCompiler :: Compiler (Item String)
customPandocCompiler =
    pandocCompilerWithTransformM defaultHakyllReaderOptions defaultHakyllWriterOptions customTransform
--------------------------------------------------------------------------------
postCtxWithTags :: Tags -> Context String
postCtxWithTags tags = tagsField "tags" tags `mappend` postCtx
--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
  dateField "date" "%0Y-%m-%d" `mappend` rootCtx
--------------------------------------------------------------------------------
rootCtx :: Context String
rootCtx =
  defaultContext <> constField "root" "https://andimiller.net"
