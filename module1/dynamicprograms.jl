### A Pluto.jl notebook ###
# v0.20.28

#> [frontmatter]
#> chapter = "1"
#> license_url = "https://github.com/mitmath/computational-thinking/blob/Fall23/LICENSE.md"
#> section = "7"
#> title = "Dynamic Programming"
#> tags = ["lecture", "module1", "optimization", "dynamic programming", "track_math", "interactive"]
#> license = "MIT"
#> description = "Find the cheapest path down a grid of costs. Enumerating every path is exponential; dynamic programming does it in one sweep. Watch the optimal path move as you tilt the landscape — live in your browser."
#> 
#>     [[frontmatter.author]]
#>     name = "MIT mathematics"
#>     url = "https://github.com/mitmath"

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ 7d000010-0000-4000-8000-000000000010
begin
    using PlutoUI, WasmMakie
end

# ╔═╡ 7d000001-0000-4000-8000-000000000001
md"""
# Dynamic Programming

"Programming" here is an old word for **optimization** (as in "linear programming") —
nothing to do with writing code. The problem, straight from the lecture:

> Given a grid of numbers, walk from the **top** to the **bottom**. At each step you may
> go straight down, down-left, or down-right. **Add up** the numbers you land on. Find
> the path with the **smallest total**.

Enumerating every path is hopeless — the number of paths grows *exponentially* with the
grid height. **Dynamic programming** finds the best one in a single sweep by reusing the
answers to overlapping subproblems. Below it all runs live in your browser.
"""

# ╔═╡ 7d000011-0000-4000-8000-000000000011
PlutoUI.TableOfContents(aside = true)

# ╔═╡ 7d000002-0000-4000-8000-000000000002
md"""
## The cost landscape

Here is our grid of costs, shown as an image — **dark is cheap**, bright is expensive.
There's a low-cost "valley" winding down it. Drag **tilt** to bend the valley left or
right, and **size** to change the grid. The cheapest top-to-bottom path is drawn in
**red**, recomputed instantly each time you move a slider.

size n = $(@bind n Slider(8:1:22; default = 16, show_value = true))

valley tilt = $(@bind tilt Slider(-1.0:0.1:1.0; default = 0.3, show_value = true))
"""

# ╔═╡ 7d000006-0000-4000-8000-000000000006
begin
    # ── WasmMakie helpers (flat, column-major; row 1 drawn at the TOP) ──────────
    function rgb_figure(pix::Vector{NTuple{4,Float64}}, nr::Int, nc::Int; px::Int = 360)
        fig = Figure(size = (px, max(40, round(Int, px * nr / nc))))
        ax = Axis(fig[1, 1])
        hidedecorations!(ax)
        hidespines!(ax)
        image!(ax, (0.0, Float64(nc)), (0.0, Float64(nr)), pix,
               Int64(nc), Int64(nr); interpolate = false)
        fig
    end
    function gray_figure(vals::Vector{Float64}, nr::Int, nc::Int; px::Int = 360)
        pix = Vector{NTuple{4,Float64}}(undef, nr * nc)
        for k in 1:(nr * nc)
            v = vals[k]
            pix[k] = (v, v, v, 1.0)
        end
        rgb_figure(pix, nr, nc; px = px)
    end
end

# ╔═╡ 7d000007-0000-4000-8000-000000000007
# Build an n×n cost grid (row-major, row 1 = top). A low-cost valley drifts across
# the grid as `tilt` changes, plus a little ripple texture. Everything is a function
# of the coordinates — no randomness (not wasm-friendly), fully reproducible.
function landscape(n::Int, tilt::Float64)
    costs = Vector{Float64}(undef, n * n)
    cc = (n + 1.0) / 2.0
    for i in 1:n
        for j in 1:n
            vc = cc + tilt * (i - cc)            # valley centre at row i
            dd = abs(j - vc)
            v = 0.30 + 0.45 * dd / n + 0.12 * (0.5 + 0.5 * sin(0.9 * i + 0.7 * j))
            v < 0.05 && (v = 0.05)
            v > 0.98 && (v = 0.98)
            costs[(i - 1) * n + j] = v
        end
    end
    return costs
end

# ╔═╡ 7d000008-0000-4000-8000-000000000008
# Dynamic programming: dp[i,j] = cheapest total from cell (i,j) down to the bottom.
# Fill from the second-to-last row upward; each cell adds its own cost to the cheapest
# of the (up to) three cells below it. THIS is the reuse of overlapping subproblems.
function solve_dp(costs::Vector{Float64}, n::Int)
    dp = copy(costs)
    for i in (n - 1):-1:1
        for j in 1:n
            best = dp[i * n + j]                 # (i+1, j)
            if j > 1 && dp[i * n + j - 1] < best
                best = dp[i * n + j - 1]
            end
            if j < n && dp[i * n + j + 1] < best
                best = dp[i * n + j + 1]
            end
            dp[(i - 1) * n + j] = costs[(i - 1) * n + j] + best
        end
    end
    return dp
end

# ╔═╡ 7d000009-0000-4000-8000-000000000009
# Walk the filled table from the cheapest top cell downward, always stepping to the
# cheapest of the three cells below. Returns the column visited at each row.
function trace_path(dp::Vector{Float64}, n::Int)
    path = Vector{Int}(undef, n)
    sj = 1
    for j in 2:n
        dp[j] < dp[sj] && (sj = j)               # cheapest entry on the top row
    end
    path[1] = sj
    for i in 1:(n - 1)
        j = path[i]
        nj = j
        best = dp[i * n + j]
        if j > 1 && dp[i * n + j - 1] < best
            best = dp[i * n + j - 1]
            nj = j - 1
        end
        if j < n && dp[i * n + j + 1] < best
            nj = j + 1
        end
        path[i + 1] = nj
    end
    return path
end

# ╔═╡ 7d00000a-0000-4000-8000-00000000000a
let
    costs = landscape(n, tilt)
    dp = solve_dp(costs, n)
    path = trace_path(dp, n)
    # paint the landscape gray, then the optimal path red
    pix = Vector{NTuple{4,Float64}}(undef, n * n)
    for i in 1:n
        for j in 1:n
            v = costs[(i - 1) * n + j]
            pix[j + (n - i) * n] = (v, v, v, 1.0)
        end
    end
    for i in 1:n
        j = path[i]
        pix[j + (n - i) * n] = (0.95, 0.25, 0.20, 1.0)
    end
    rgb_figure(pix, n, n)
end

# ╔═╡ 7d000003-0000-4000-8000-000000000003
md"""
## The trick: overlapping subproblems

The naive method re-walks the whole grid for every path. But notice: the cheapest way
down from a cell *only depends on the three cells below it*. So if we already know the
best total-to-the-bottom for every cell in row $i+1$, each cell in row $i$ is just

$$\text{dp}[i,j] = \text{cost}[i,j] + \min\big(\text{dp}[i{+}1,j{-}1],\ \text{dp}[i{+}1,j],\ \text{dp}[i{+}1,j{+}1]\big).$$

One sweep from the bottom up fills the whole table. Below is that **cost-to-the-bottom**
table for the same grid — dark cells are cheap launch points. The optimal path simply
follows the dark gradient down from the cheapest top cell.
"""

# ╔═╡ 7d00000b-0000-4000-8000-00000000000b
let
    costs = landscape(n, tilt)
    dp = solve_dp(costs, n)
    # normalise dp to 0..1 for display
    lo = dp[1]
    hi = dp[1]
    for k in 2:(n * n)
        dp[k] < lo && (lo = dp[k])
        dp[k] > hi && (hi = dp[k])
    end
    span = hi - lo
    span <= 0.0 && (span = 1.0)
    disp = Vector{Float64}(undef, n * n)
    for i in 1:n
        for j in 1:n
            disp[j + (n - i) * n] = (dp[(i - 1) * n + j] - lo) / span
        end
    end
    gray_figure(disp, n, n)
end

# ╔═╡ 7d000004-0000-4000-8000-000000000004
md"""
## Why it's a huge speed-up

- **Naive:** enumerate every path → about $3^{n}$ of them for an $n$-row grid. At $n=40$
  that's already more paths than there are atoms in your body.
- **Dynamic programming:** fill an $n \times n$ table once → about $n^2$ work. At $n=40$,
  1,600 little `min` operations. Done.

Same answer, exponentially less effort, because we **remembered** each subproblem instead
of recomputing it. Next up: this exact idea carves seams out of images.
"""

# ╔═╡ 7d000005-0000-4000-8000-000000000005
md"""
# Summary

- A **dynamic program** breaks an optimization into **overlapping subproblems** and
  reuses their answers instead of recomputing them.
- Minimum-cost-path: the best route from a cell depends only on the cells just below it,
  so one bottom-up sweep fills a table of "cheapest cost to the bottom".
- This turns an **exponential** search into a **quadratic** one.

The red path and the cost-to-go table above are live WebAssembly islands — drag the
sliders and the dynamic program re-solves in your browser.
""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
WasmMakie = "782397d3-b2e0-4093-86f4-3070b4a5c6bd"

[sources]
WasmMakie = {rev = "v0.1.3", url = "https://github.com/GroupTherapyOrg/WasmMakie.jl"}

[compat]
PlutoUI = "~0.7.83"
WasmMakie = "~0.1.3"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.6"
manifest_format = "2.0"
project_hash = "ed96a65ac2ea39ef97240be43398759a5bb5caed"

[[deps.AbstractPlutoDingetjes]]
git-tree-sha1 = "6c3913f4e9bdf6ba3c08041a446fb1332716cbc2"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.4.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "67e11ee83a43eb71ddc950302c53bf33f0690dfe"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.12.1"
weakdeps = ["StyledStrings"]

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.3.0+1"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.7.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FixedPointNumbers]]
deps = ["Random", "Statistics"]
git-tree-sha1 = "59af96b98217c6ef4ae0dfe065ac7c20831d1a84"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.6"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "d1a86724f81bcd184a38fd284ce183ec067d71a0"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "1.0.0"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "0ee181ec08df7d7c911901ea38baf16f755114dc"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "1.0.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.JuliaSyntaxHighlighting]]
deps = ["StyledStrings"]
uuid = "ac6e5ff7-fb65-4e79-a425-ec3bc9c03011"
version = "1.12.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "OpenSSL_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.15.0+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "OpenSSL_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.3+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.12.0"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.Markdown]]
deps = ["Base64", "JuliaSyntaxHighlighting", "StyledStrings"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2025.11.4"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.3.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.29+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.5.4+0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Downloads", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "e189d0623e7ce9c37389bac17e80aac3b0302e75"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.83"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

    [deps.Statistics.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.Tricks]]
git-tree-sha1 = "311349fd1c93a31f783f977a71e8b062a57d4101"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.13"

[[deps.URIs]]
git-tree-sha1 = "bef26fb046d031353ef97a82e3fdb6afe7f21b1a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.6.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.WasmMakie]]
deps = ["Base64"]
git-tree-sha1 = "7fe9806ba609b6aca12d7a2ecb30071efa4fc221"
repo-rev = "v0.1.3"
repo-url = "https://github.com/GroupTherapyOrg/WasmMakie.jl"
uuid = "782397d3-b2e0-4093-86f4-3070b4a5c6bd"
version = "0.1.3"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.3.1+2"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.15.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.64.0+1"
"""

# ╔═╡ Cell order:
# ╟─7d000001-0000-4000-8000-000000000001
# ╠═7d000010-0000-4000-8000-000000000010
# ╠═7d000011-0000-4000-8000-000000000011
# ╟─7d000002-0000-4000-8000-000000000002
# ╠═7d000006-0000-4000-8000-000000000006
# ╠═7d000007-0000-4000-8000-000000000007
# ╠═7d000008-0000-4000-8000-000000000008
# ╠═7d000009-0000-4000-8000-000000000009
# ╠═7d00000a-0000-4000-8000-00000000000a
# ╟─7d000003-0000-4000-8000-000000000003
# ╠═7d00000b-0000-4000-8000-00000000000b
# ╟─7d000004-0000-4000-8000-000000000004
# ╟─7d000005-0000-4000-8000-000000000005
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
