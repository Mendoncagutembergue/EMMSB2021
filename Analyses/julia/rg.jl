using StatsPlots, LaTeXStrings

function readxvg(file)
  t = Float64[]
  rg = Float64[]
  open(file,"r") do io
    for line in eachline(io)
      if line[1] in ['#','@'] # skip comments
        continue
      end
      line = split(line)
      push!(t,parse(Float64,line[1]))
      push!(rg,parse(Float64,line[2]))
    end
  end
  return t, rg
end

# Work dir
if ! isdir(ARGS[1])
  println("Run with julia rg.jl \$work")
  exit()
end
work=ARGS[1]

# Read data
println("Reading data...")
t0, rg0 = readxvg("$work/Simulations/AAQAA_0vv/0/rg.xvg")
t60, rg60 = readxvg("$work/Simulations/AAQAA_60vv/0/rg.xvg")

# Plot
println("Plotting...")
default(fontfamily="Computer Modern",linewidth=2,framestyle=:box,grid=false)
scalefontsizes(1.4)

density(rg0,xlabel=L"R_g/\mathrm{nm}",
            ylabel="Probability density",
            label="pure Water")

density!(rg60,xlabel=L"R_g/\mathrm{nm}",
              ylabel="Probability density",
              label="Water/TFE")

savefig("./rg.pdf")
println("Wrote file rg.pdf")



