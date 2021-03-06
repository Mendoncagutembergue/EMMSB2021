# Load packages
using PDBTools, ComplexMixtures 

# Repository dir
if (! isdir(ARGS[1])) || (! isdir(ARGS[2]))
  println("Run with: cm_water0.jl \$repo \$work")
  exit()
end
repo = ARGS[1]
work = ARGS[2]

# Load PDB file of the system
atoms = readPDB("$repo/Simulations/Final/system0.pdb")

# Select the protein and the solvents
protein = select(atoms,"protein")
water = select(atoms,"resname SOL and not name MW")

# Setup solute
solute = Selection(protein,nmols=1)

# Setup solvent
solvent = Selection(water,natomspermol=3)

# Setup the Trajectory structure
trajectory = Trajectory("$repo/Simulations/Final/production0.xtc",solute,solvent)

# Options
options = Options(dbulk=10)

# Run the calculation and get results
results = mddf(trajectory,options)

# Save the reults to recover them later if required
save(results,"$work/Simulations/cm_water0.json")

