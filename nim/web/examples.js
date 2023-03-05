var example_concentric = `{
"simulation": {
    "eps": 1e-6,
    "dt": 1e-3,
    "max_steps": 2500000,
    "equal_time": false,
    "accuracy": false,
    "linear": true,
    "verbose": false
},
"objects": [
    { 
        "type": "concentric", 
        "scaling_function": {
            "type": "linear",
            "min_scale": 1.0,
            "max_scale": 4.0,
            "steps": 150
        },
        "object": {
            "type": "masked_circle",
            "pos": [ 0.5, 0.5],
            "rad": 0.125,
            "damp": 0.999999,
            "mask": {
                "type": "nholes",
                "n": 4,
                "gap": 8e-3,
                "offset": 0.0
            }
        }
    },
    { "type": "circle", "pos": [ 0.5, 0.5], "rad": 0.12501, "damp": 1.0 },
    { "type": "circle", "pos": [ 0.5, 0.5], "rad": 0.4999, "damp": 1.0 }
],
"particles": [ 
    { 
        "type": "single", 
        "pos": [0.501, 0.97], 
        "vel": [0.1, 0.0] 
    } 
],
"forces": [ { "type": "gravity", "g": -1.0 } ],
"observers": [
    {
        "type": "pgm", 
        "filename": "canvas", 
        "blend": "add",
        "box": { "type": "ref", "name": "boundary"}
    },
    { "type": "step", "interval": 100000 }
],
"neighborlist": {
    "type": "cell",
    "ncells": [100, 100],
    "buffer": 0.02,
    "box": { "type": "ref", "name": "boundary" }
}
}
`;

var example_plinko_simple = `{
"simulation": {
    "eps": 1e-6,
    "dt": 1e-2,
    "max_steps": 1000000,
    "equal_time": false,
    "accuracy": false,
    "linear": false,
    "record_objects": true
},
"objects": [
    {
        "type": "tri-lattice", "rows": 4, "columns": 8,
        "object": {
            "type": "circle",
            "pos": [ 0.5, 0.5],
            "rad": 0.45,
            "damp": 0.95
        }
    }
],
"particles": [
    {
        "type": "single",
        "pos": [4.0, 6.6],
        "vel": [0.1, 0.0]
    }
],
"forces": [ { "type": "gravity", "g": -1.0 } ],
"interrupts": [
    {
        "type": "collision",
        "object": {
            "type": "ref",
            "name": "bottom"
        }
    }
],
"observers": [
    {
        "type": "pgm",
        "filename": "canvas",
        "blend": "add",
        "box": { "type": "ref", "name": "boundary"}
    },
    { "type": "step", "interval": 1000 }
]
}`;

var example_orbits = `{
"simulation": {
    "eps": 1e-6,
    "dt": 1e-3,
    "max_steps": 5000,
    "equal_time": false,
    "accuracy": false,
    "linear": false,
    "record_objects": false,
    "verbose": false
},
"objects": [ { "type": "circle", "pos": [ 0.5, 0.5], "rad": 0.5, "damp": 1.0} ],
"particles": [ 
    { 
        "type": "uniform", 
        "p0": [0.5, 0.99], 
        "p1": [0.5, 0.99], 
        "v0": [-0.50, 0.0], 
        "v1": [0.50, 0.0], 
        "N": 2000
    }
],
"forces": [ { "type": "gravity", "g": -1.0 } ],
"observers": [
    {
        "type": "pgm", 
        "filename": "test.pgm", 
        "blend": "add",
        "norm": "eq_hist",
        "box": { "type": "box", "ll": [0.0,0.0], "uu": [1.0,1.0] }
    },
    {"type": "step", "interval": 10}
]
}`;

var examples = {
    "concentric-plus": example_concentric,
    "plinko-simple": example_plinko_simple,
    "orbits": example_orbits,
}