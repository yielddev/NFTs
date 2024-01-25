import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";

const tree = StandardMerkleTree.load(JSON.parse(fs.readFileSync("tree.json", "utf8")));

for (const [i, v] of tree.entries()) {
    if(v[0] === '0x00000000000000000000000000000000000001a4') {
        const proof = tree.getProof(i);
        console.log("Value: ", v);
        console.log("Proof: ", proof);
    }
}

// output leaf hash

console.log("Leaf Hash: ", tree.leafHash(["0x00000000000000000000000000000000000001a4", "0"]))
//0xdf248fb2594c2d2f88aa5844f799495ca629e3433619adc344edb43c6cda09ff