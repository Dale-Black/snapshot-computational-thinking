### A Pluto.jl notebook ###
# v0.20.28

#> [frontmatter]
#> chapter = "1"
#> license_url = "https://github.com/mitmath/computational-thinking/blob/Fall23/LICENSE.md"
#> section = "3"
#> title = "Automatic Differentiation"
#> tags = ["lecture", "module1", "track_math", "derivative", "automatic differentiation", "interactive"]
#> license = "MIT"
#> description = "How does a computer get exact derivatives without calculus by hand or finite differences? Forward-mode automatic differentiation with dual numbers — built from scratch and running live in your browser."
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

# ╔═╡ ad000010-0000-4000-8000-000000000010
begin
    using PlutoUI, WasmMakie
end

# ╔═╡ ad000001-0000-4000-8000-000000000001
md"""
# Automatic Differentiation

Derivatives are everywhere in computing — optimisation, machine learning, physics.
But how does a computer *find* a derivative? Not by doing calculus on paper, and
(it turns out) not by the approximate finite differences you may have seen. The
real workhorse is **automatic differentiation (AD)**, and the forward-mode version
is delightfully simple: a tiny new kind of number.

The MIT lecture uses `ForwardDiff.jl`. WebAssembly can't run that package, so here
we **build forward-mode AD from scratch** in a dozen lines — and it computes the
*exact* derivative, live in your browser.
"""

# ╔═╡ ad000011-0000-4000-8000-000000000011
PlutoUI.TableOfContents(aside = true)

# ╔═╡ ad000002-0000-4000-8000-000000000002
md"""
## First, a reminder: the derivative

The derivative $f'(x)$ is the slope of $f$ at $x$. The definition you learned is a
limit of a **finite difference**:

$$f'(x) \approx \frac{f(x+h) - f(x)}{h}, \qquad h \to 0.$$

Let's watch that for $f = \sin$ at $x = 1$, where the true answer is $\cos(1) \approx 0.5403$.
Shrink the step $h$ and the estimate creeps toward it — but never *exactly*, and if
you make $h$ too small, floating-point round-off ruins it. AD will fix both problems.
"""

# ╔═╡ ad000003-0000-4000-8000-000000000003
md"""step size h = $(@bind h Slider([1.0, 0.3, 0.1, 0.03, 0.01, 0.001, 0.0001, 1.0e-5, 1.0e-6]; default = 0.01, show_value = true))"""

# ╔═╡ ad000005-0000-4000-8000-000000000005
md"""
## Forward-mode AD: dual numbers

Here is the trick. Invent a new symbol $\varepsilon$ with the rule $\varepsilon^2 = 0$
(it is *not* a real number — think of it as "infinitely small"). A **dual number**
is $a + b\,\varepsilon$. Now feed $x + \varepsilon$ into any function and expand:

$$f(x + \varepsilon) = f(x) + f'(x)\,\varepsilon + \tfrac12 f''(x)\,\varepsilon^2 + \dots
= f(x) + f'(x)\,\varepsilon$$

— every term with $\varepsilon^2$ vanishes! So the **value** lands in the first slot
and the **exact derivative** lands in the $\varepsilon$ slot, for free. We just need a
number type that carries both slots and knows the arithmetic rules.
"""

# ╔═╡ ad000006-0000-4000-8000-000000000006
begin
    # A dual number carries a value `v` = f(x) and a derivative `d` = f'(x).
    struct Dual
        v::Float64
        d::Float64
    end

    # Arithmetic: each rule is just the sum / product / quotient rule of calculus.
    Base.:+(a::Dual, b::Dual) = Dual(a.v + b.v, a.d + b.d)
    Base.:-(a::Dual, b::Dual) = Dual(a.v - b.v, a.d - b.d)
    Base.:*(a::Dual, b::Dual) = Dual(a.v * b.v, a.v * b.d + a.d * b.v)      # product rule
    Base.:/(a::Dual, b::Dual) = Dual(a.v / b.v, (a.d * b.v - a.v * b.d) / (b.v * b.v))

    # Mixing a dual with a plain number (a constant has derivative 0).
    Base.:+(a::Dual, b::Real) = Dual(a.v + b, a.d)
    Base.:+(a::Real, b::Dual) = Dual(a + b.v, b.d)
    Base.:-(a::Dual, b::Real) = Dual(a.v - b, a.d)
    Base.:-(a::Real, b::Dual) = Dual(a - b.v, -b.d)
    Base.:-(a::Dual)          = Dual(-a.v, -a.d)
    Base.:*(a::Dual, b::Real) = Dual(a.v * b, a.d * b)
    Base.:*(a::Real, b::Dual) = Dual(a * b.v, a * b.d)
    Base.:/(a::Dual, b::Real) = Dual(a.v / b, a.d / b)

    # Elementary functions via the chain rule.
    Base.sin(a::Dual) = Dual(sin(a.v),  cos(a.v) * a.d)
    Base.cos(a::Dual) = Dual(cos(a.v), -sin(a.v) * a.d)
    Base.exp(a::Dual) = Dual(exp(a.v),  exp(a.v) * a.d)
end

# ╔═╡ ad000004-0000-4000-8000-000000000004
fd_estimate = (sin(1.0 + h) - sin(1.0)) / h

# ╔═╡ ad000012-0000-4000-8000-000000000012
md"""
**finite-difference estimate** $f'(1) \approx$ $(fd_estimate)

**exact** $\cos(1) =$ $(cos(1.0))

The gap is the error — try the smallest steps and watch round-off creep back in.
"""

# ╔═╡ ad000007-0000-4000-8000-000000000007
# The whole of forward-mode AD: evaluate f at the dual number x + 1·ε and read off
# the ε-slot. No finite differences, no round-off — the exact slope.
ad_derivative(f, x::Float64) = f(Dual(x, 1.0)).d

# ╔═╡ ad000008-0000-4000-8000-000000000008
# Example functions. Note: NO type annotation on `x`, so the SAME code runs on plain
# Float64 (to draw the curve) and on Dual numbers (to get the derivative).
function example(x, which::Int64)
    if which == 1
        return x * x - 2.0          # f(x) = x² − 2 ,  f′ = 2x
    elseif which == 2
        return sin(x)               # f(x) = sin x ,   f′ = cos x
    else
        return x * x * x - 2.0 * x + 1.0   # f(x) = x³ − 2x + 1 , f′ = 3x² − 2
    end
end

# ╔═╡ ad000009-0000-4000-8000-000000000009
md"""
## See it work

Pick a function and a point. The number is the derivative our dual numbers compute;
the orange line is the tangent with that slope — drag $x_0$ and it stays glued to the curve.

example f = $(@bind which Slider(1:3, show_value = true, default = 1))

point x₀ = $(@bind x0 Slider(-2.5:0.1:2.5, show_value = true, default = 1.0))
"""

# ╔═╡ ad00000a-0000-4000-8000-00000000000a
slope_ad = ad_derivative(u -> example(u, which), x0)

# ╔═╡ ad000013-0000-4000-8000-000000000013
md"""**f′(x₀) by dual numbers = $(slope_ad)**  — the exact slope of the tangent line below."""

# ╔═╡ ad00000b-0000-4000-8000-00000000000b
let
    # sample the curve with an integer loop (StepRangeLen iteration is not
    # wasm-compilable yet), exactly like the Newton notebook
    lo = -2.5
    hi = 2.5
    steps = 240
    xs = Float64[]
    ys = Float64[]
    for k in 0:steps
        t = lo + (hi - lo) * k / steps
        push!(xs, t)
        push!(ys, example(t, which))
    end

    # the tangent line through (x0, f(x0)) with the AD-computed slope
    y0 = example(x0, which)
    m = ad_derivative(u -> example(u, which), x0)

    fig = Figure(size = (480, 320))
    ax = Axis(fig[1, 1])
    lines!(ax, xs, ys)                                   # the curve f
    lines!(ax, [lo, hi], [0.0, 0.0])                     # the x-axis
    lines!(ax, [lo, hi], [y0 + m * (lo - x0), y0 + m * (hi - x0)])  # tangent from AD
    lines!(ax, [x0, x0], [y0 - 0.4, y0 + 0.4])           # mark the point x0
    fig
end

# ╔═╡ ad00000c-0000-4000-8000-00000000000c
md"""
## Why this is a big deal

We never wrote a single derivative formula for `example` — we wrote the function
*once*, and the dual-number arithmetic carried the derivative through automatically.
That is exactly how `ForwardDiff.jl` and the autodiff engines inside PyTorch, JAX and
Flux work (just with more bookkeeping and more elementary functions defined).

The original MIT lecture pushes this further: derivatives of **multivariate** functions
(the *gradient*) and of **vector-valued** functions that *transform images* (the
*Jacobian*). The idea is identical — carry an $\varepsilon$ in every input direction —
only the bookkeeping grows.
"""

# ╔═╡ ad00000d-0000-4000-8000-00000000000d
md"""
# Summary

- A **finite difference** only *approximates* the derivative, and fights round-off.
- A **dual number** $a + b\,\varepsilon$ with $\varepsilon^2 = 0$ carries a value and a
  derivative together; pushing $x + \varepsilon$ through a function yields
  $f(x) + f'(x)\,\varepsilon$ — the **exact** derivative, for free.
- Implementing it is just overloading `+`, `*`, `sin`, … on a two-field struct.
- This is **forward-mode automatic differentiation**, the same idea that powers modern
  machine-learning frameworks.

Every figure above is a live WebAssembly island — the AD runs in your browser.
""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
WasmMakie = "782397d3-b2e0-4093-86f4-3070b4a5c6bd"

[sources]
WasmMakie = {url = "https://github.com/GroupTherapyOrg/WasmMakie.jl"}

[compat]
PlutoUI = "~0.7.83"
WasmMakie = "~0.1.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.6"
manifest_format = "2.0"
project_hash = "528a15ccaaea2a8f2cfb8a3b8ef12bd3bc6e7ee4"

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
git-tree-sha1 = "de6c9a45585e892ac96fa7ad9fd3b1d3d61277ec"
repo-url = "https://github.com/GroupTherapyOrg/WasmMakie.jl"
uuid = "782397d3-b2e0-4093-86f4-3070b4a5c6bd"
version = "0.1.0"

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
# ╟─ad000001-0000-4000-8000-000000000001
# ╠═ad000010-0000-4000-8000-000000000010
# ╠═ad000011-0000-4000-8000-000000000011
# ╟─ad000002-0000-4000-8000-000000000002
# ╟─ad000003-0000-4000-8000-000000000003
# ╠═ad000004-0000-4000-8000-000000000004
# ╟─ad000012-0000-4000-8000-000000000012
# ╟─ad000005-0000-4000-8000-000000000005
# ╠═ad000006-0000-4000-8000-000000000006
# ╠═ad000007-0000-4000-8000-000000000007
# ╠═ad000008-0000-4000-8000-000000000008
# ╟─ad000009-0000-4000-8000-000000000009
# ╠═ad00000a-0000-4000-8000-00000000000a
# ╟─ad000013-0000-4000-8000-000000000013
# ╠═ad00000b-0000-4000-8000-00000000000b
# ╟─ad00000c-0000-4000-8000-00000000000c
# ╟─ad00000d-0000-4000-8000-00000000000d
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
