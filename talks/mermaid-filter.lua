-- modeled on graphviz-filter.lua
-- mmdc can't pipe stdin to stdout, so we render via a temporary directory

local mmdcPath = os.getenv("MMDC") or "mmdc"

-- set this to a json file containing e.g. {"args": ["--no-sandbox"]} if
-- chromium refuses to launch
local puppeteerConfig = os.getenv("PUPPETEER_CONFIG")

-- note: we deliberately keep pandoc's working directory and use absolute
-- paths into the temp dir; puppeteer config-searches from cwd upward and
-- only stops at $HOME, so running inside /tmp makes it walk to / and fail
local diagramCount = 0

local function mermaid(code)
    return pandoc.system.with_temporary_directory("mermaid", function(tmpdir)
        local infile = pandoc.path.join({tmpdir, "diagram.mmd"})
        local outfile = pandoc.path.join({tmpdir, "diagram.svg"})

        local f = assert(io.open(infile, "w"))
        f:write(code)
        f:close()

        local args = {"-i", infile, "-o", outfile, "-b", "transparent", "-t", "dark", "-q"}
        if puppeteerConfig then
            table.insert(args, "-p")
            table.insert(args, puppeteerConfig)
        end
        pandoc.pipe(mmdcPath, args, "")

        local svg = assert(io.open(outfile, "r"))
        local content = svg:read("a")
        svg:close()

        -- mmdc gives every svg the id "my-svg"; with several diagrams inlined
        -- into one page, url(#...) marker references resolve to the first
        -- (possibly display:none) svg and the arrowheads vanish
        diagramCount = diagramCount + 1
        content = content:gsub('my%-svg', 'mermaid-svg-' .. diagramCount)

        -- mermaid draws arrowheads as fixed 12-unit markers which don't scale
        -- with fontSize, leaving them near-invisible next to large nodes
        content = content:gsub('markerWidth="12"', 'markerWidth="18"')
        content = content:gsub('markerHeight="12"', 'markerHeight="18"')

        return content
    end)
end

function CodeBlock(block)
    if block.classes[1] ~= "mermaid" then
        return nil
    end

    local success, img = pcall(mermaid, block.text)

    if not success then
        io.stderr:write(tostring(img))
        io.stderr:write('\n')
        error 'Image conversion failed. Aborting.'
    end

    return pandoc.RawBlock('html', img)
end

return {
    {CodeBlock = CodeBlock},
}
