### A Pluto.jl notebook ###
# v0.16.0

using Markdown
using InteractiveUtils

# ╔═╡ 5a3f9995-3d45-40b9-af98-7de36713a942
begin
    import Pkg
    # activate a clean environment
    Pkg.activate(mktempdir())

    Pkg.add("Gumbo,Cascadia,HTTP,Plots,DataFrames" |> x->split(x, ',') .|>
		name -> Pkg.PackageSpec(name=name)
    )
	using Gumbo,Cascadia, HTTP, Plots, DataFrames
end

# ╔═╡ 224bf02a-bc07-4791-a1a8-be06747359fe
@eval(PlutoRunner, table_row_display_limit = 270)

# ╔═╡ 83753096-85ba-403b-aa9f-c0fc75d2823b
years_with_statistics = [
	2021:-1:2006...,
	2004,
	2003,
	1997,
	1995,
	1991,
	1989
]

# ╔═╡ f0a2d124-1cc4-4da7-9e58-847bf3e8f566
get_competition_url(year) = "https://stats.ioinformatics.org/results/$year"

# ╔═╡ 309dad61-df77-4347-b397-048774915f24
read_url(url) = url |> HTTP.get |> x -> x.body |> String |> parsehtml

# ╔═╡ 57308935-f6a9-4ecc-ae6c-0d5aca5ab967
get_competition_page(year) = get_competition_url(year) |> read_url

# ╔═╡ 687c7f1e-e383-42fb-8faa-101ed2a8a681
function get_tasks_statistics(year)
	h = get_competition_page(year)
	
	task_names = String[]
	task_scores = Vector{Float64}[]
	n_tasks = 0
	function handle(x::HTMLElement{:a})
		n_tasks += 1
		push!(task_names, x.attributes["href"]) 
		push!(task_scores, Float64[])
	end
	
	idx = -1
	function handle(x::HTMLText)
		idx += 1
		x.text == "–" && return
		push!(task_scores[(idx % n_tasks) + 1], min(100.0, parse(Float64, x.text))) 
	end
	
	for elm ∈ eachmatch(Selector(".taskscore"), h.root)
		handle(elm[1])
	end
	res = Dict()
	for i ∈ 1:n_tasks
		res[task_names[i]] = task_scores[i] |> sort!
	end
	res |> collect
end

# ╔═╡ 53c99b97-7e13-4bfc-bbb5-c208dcb3b083
get_all_tasks() = vcat(
	asyncmap(get_tasks_statistics, years_with_statistics)...)

# ╔═╡ 30cda10a-9545-444c-88ac-e6664ef912c1
tasks = get_all_tasks()

# ╔═╡ 632d7079-83e7-4fbb-b10b-b51fc871d43d
function dist_to_gradient(dist)
	"Take a distribution and changes it to a cumulative gradient you can draw"
	stats = zeros(Float64, 101) 
	for i ∈ dist
		stats[round(Int, i) + 1] += 1 
	end
	stats = cumsum(stats)
	stats = stats ./ stats[end] 
	stats
end

# ╔═╡ 46e5ab26-7ddc-4377-80c7-42afac6795a2
function plot_dist(scores)
	dist = dist_to_gradient(scores)
	# plot(dist, xtick=false, ytick=false, cbar=false, 
	# 		size=(1000, 150), legend=false,
	# 		fillrange=0)
	# heatmap(reshape(dist, 1, :), 
	# 		xtick=false, ytick=false, cbar=false, size=(1000, 150))
	ax = plot(dist, xtick=false, ytick=false, cbar=false, 
		size=(1000, 150), legend=false,
		fill_between=0
	)
	histogram(
		ax, 
		scores,
		normalize=:probability,
		xtick=false, ytick=false, cbar=false, 
		size=(1000, 150), legend=false,
		bins=0.0:101/15:101.0
	)
end

# ╔═╡ 01c93793-9ceb-426b-aa16-2f6af64d569f
plots = [name => plot_dist(scores) for (name, scores) ∈ tasks]

# ╔═╡ 8ad30675-6c5d-41bc-b8d9-203ec3eca49a
function to_dataframe(plots)
	names = [i for (i,j) ∈ plots]
	plots = [j for (i,j) ∈ plots]
	DataFrame(name=names, cumulative_plot=plots)
end

# ╔═╡ d1848f8b-3dbe-4a9f-bb3c-3b7a0815180c
to_dataframe(plots) # for pretty prints

# ╔═╡ Cell order:
# ╠═224bf02a-bc07-4791-a1a8-be06747359fe
# ╠═d1848f8b-3dbe-4a9f-bb3c-3b7a0815180c
# ╠═5a3f9995-3d45-40b9-af98-7de36713a942
# ╠═83753096-85ba-403b-aa9f-c0fc75d2823b
# ╠═f0a2d124-1cc4-4da7-9e58-847bf3e8f566
# ╠═309dad61-df77-4347-b397-048774915f24
# ╠═57308935-f6a9-4ecc-ae6c-0d5aca5ab967
# ╠═687c7f1e-e383-42fb-8faa-101ed2a8a681
# ╠═53c99b97-7e13-4bfc-bbb5-c208dcb3b083
# ╠═30cda10a-9545-444c-88ac-e6664ef912c1
# ╠═632d7079-83e7-4fbb-b10b-b51fc871d43d
# ╠═46e5ab26-7ddc-4377-80c7-42afac6795a2
# ╠═01c93793-9ceb-426b-aa16-2f6af64d569f
# ╠═8ad30675-6c5d-41bc-b8d9-203ec3eca49a
