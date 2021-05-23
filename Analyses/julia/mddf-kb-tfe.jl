using Plots, LaTeXStrings, ComplexMixtures, PDBTools

if (!isdir(ARGS[1])) || (!isdir(ARGS[2])) 
  println("Run with: julia mddf_kb.jl \$repo \$work")
  exit()
end
repo = ARGS[1]
work = ARGS[2]

atoms = readPDB("$repo/Simulations/Final/system60.pdb")
results = ComplexMixtures.load("$work/Simulations/cm_tfe60.json")

# Default plot parameters
default(fontfamily="Computer Modern",grid=false,framestyle=:box,linewidth=2)

# Complete MDDF
plot(results.d,results.mddf,xlabel="r/Å",ylabel="mddf",label="Total")

# Fluorine atoms
f_contrib = contrib(results,results.solvent_atom,
                    select(atoms,"resname TFE and element F"))
plot!(results.d,f_contrib,label="Fluorine")

# Carbon atoms
c_contrib = contrib(results,results.solvent_atom,
                    select(atoms,"resname TFE and element C"))
plot!(results.d,c_contrib,label="Carbon")

# Aliphatic hydrogens
ha_contrib = contrib(results,results.solvent_atom,
                     select(atoms,"name H21 or name H22"))
plot!(results.d,ha_contrib,label="Aliphatic H")

# Hydroxyl hydrogen
hy_contrib = contrib(results,results.solvent_atom,
                     select(atoms,"resname TFE and name H"))
plot!(results.d,hy_contrib,label="Hydroxyl H")

# Hydroxyl oxygen
ho_contrib = contrib(results,results.solvent_atom,
                     select(atoms,"resname TFE and name O"))
plot!(results.d,hy_contrib,label="Hydroxyl O")

# Save figure
savefig("$work/Simulations/mddf-tfe.pdf")

# KB-integral
#plot(results.d,results.kb/1000,xlabel=L"\mathrm{r} / \mathrm{\AA}", ylabel=L"{G_{pc}} \ (r) / \mathrm{L\ mol^{-1}}",#label=false,framestyle=:box,c=:navyblue,dpi=300,xtickfontsize=18,ytickfontsize=18,xguidefontsize=18,yguidefontsize=18,#legendfontsize=18,lw=3,minorticks=Integer)

# Save figure
#savefig("./kb-integral-tfe.png")

