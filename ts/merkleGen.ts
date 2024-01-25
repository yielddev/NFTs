import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import { ethers } from "ethers";
import fs from "fs";

const values = [
    ["0x00000000000000000000000000000000000001a4", "0"],
    ["0x00000000000000000000000000000000000001a4", "1"],
]

const tree = StandardMerkleTree.of(values, ["address", "uint256"])

console.log("Merkle Root: ", tree.root);

fs.writeFileSync("tree.json", JSON.stringify(tree.dump()));
