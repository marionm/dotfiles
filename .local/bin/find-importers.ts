#!/usr/bin/env tsx

import { Project, SourceFile } from "ts-morph";
import * as path from "path";
import * as fs from "fs";

const args = process.argv.slice(2);

let maxDepth: number | undefined = 1; // default: immediate importers only
const depthIndex = args.findIndex(arg => arg === "-d" || arg === "--depth");

if (depthIndex !== -1) {
  const nextArg = args[depthIndex + 1];
  const nextIsNumber = nextArg && /^\d+$/.test(nextArg);

  if (nextIsNumber) {
    maxDepth = parseInt(nextArg, 10);
    if (maxDepth < 1) {
      console.error("Error: --depth must be a positive integer");
      process.exit(1);
    }
  } else {
    maxDepth = undefined; // unlimited depth
  }
}

const targetFile = args.find((arg, i) => {
  if (arg.startsWith("-")) return false;
  if (depthIndex === -1) return true;
  const nextArg = args[depthIndex + 1];
  const nextIsNumber = nextArg && /^\d+$/.test(nextArg);
  return !(nextIsNumber && i === depthIndex + 1);
});

if (!targetFile) {
  console.error("Usage: find-importers [options] <file-path>");
  console.error("Options:");
  console.error("  -d, --depth [N]  Show import tree (unlimited depth, or N levels)");
  console.error("Example: find-importers app/javascript/components/Button.tsx");
  console.error("Example: find-importers -d app/javascript/components/Button.tsx");
  console.error("Example: find-importers -d 2 app/javascript/components/Button.tsx");
  process.exit(1);
}

function findTsConfig(startDir: string): string | null {
  let dir = startDir;
  while (dir !== path.dirname(dir)) {
    const tsConfigPath = path.join(dir, "tsconfig.json");
    if (fs.existsSync(tsConfigPath)) {
      return tsConfigPath;
    }
    dir = path.dirname(dir);
  }
  return null;
}

const cwd = process.cwd();
const tsConfigPath = findTsConfig(cwd);

if (!tsConfigPath) {
  console.error("Could not find tsconfig.json in current directory or parents");
  process.exit(1);
}

const projectRoot = path.dirname(tsConfigPath);
const absoluteTarget = path.isAbsolute(targetFile)
  ? targetFile
  : path.resolve(cwd, targetFile);

console.error(`Loading project from ${tsConfigPath}...`);

const project = new Project({
  tsConfigFilePath: tsConfigPath,
  skipAddingFilesFromTsConfig: true,
  compilerOptions: {
    allowJs: true,
  },
});

const sourceDirs = ["app/javascript", "src", "lib"].map(d => path.join(projectRoot, d));
for (const dir of sourceDirs) {
  if (fs.existsSync(dir)) {
    project.addSourceFilesAtPaths([path.join(dir, "**/*.{ts,tsx}")]);
    project.addSourceFilesAtPaths([path.join(dir, "**/*.{js,jsx}")]);
  }
}

const sourceFile = project.getSourceFile(absoluteTarget);

if (!sourceFile) {
  console.error(`Could not find source file: ${absoluteTarget}`);
  process.exit(1);
}

const isRecursive = maxDepth === undefined || maxDepth > 1;
const depthLabel = maxDepth === undefined ? " (unlimited)" : maxDepth > 1 ? ` (depth: ${maxDepth})` : "";
console.error(`Finding files that import ${targetFile}${depthLabel}...\n`);

interface TreeNode {
  file: SourceFile;
  children: TreeNode[];
}

function buildImportTree(file: SourceFile, visited: Set<string>, depth: number = 1): TreeNode[] {
  if (maxDepth !== undefined && depth > maxDepth) return [];

  const refs = file.getReferencingSourceFiles();
  const nodes: TreeNode[] = [];

  for (const ref of refs) {
    const filePath = ref.getFilePath();
    if (visited.has(filePath)) continue;
    visited.add(filePath);

    nodes.push({
      file: ref,
      children: buildImportTree(ref, visited, depth + 1),
    });
  }

  return nodes;
}

function printTree(nodes: TreeNode[], prefix: string = ""): void {
  for (let i = 0; i < nodes.length; i++) {
    const node = nodes[i];
    const isLast = i === nodes.length - 1;
    const relativePath = path.relative(cwd, node.file.getFilePath());
    console.log(`${prefix}${isLast ? "└── " : "├── "}${relativePath}`);
    if (node.children.length > 0) {
      printTree(node.children, prefix + (isLast ? "    " : "│   "));
    }
  }
}

function countNodes(nodes: TreeNode[]): number {
  return nodes.reduce((sum, n) => sum + 1 + countNodes(n.children), 0);
}

if (isRecursive) {
  const visited = new Set<string>([absoluteTarget]);
  const tree = buildImportTree(sourceFile, visited);

  if (tree.length === 0) {
    console.log("No files import this module.");
  } else {
    printTree(tree);
    console.error(`\nFound ${countNodes(tree)} file(s) in import tree.`);
  }
} else {
  const referencingFiles = sourceFile.getReferencingSourceFiles();

  if (referencingFiles.length === 0) {
    console.log("No files import this module.");
  } else {
    for (const file of referencingFiles) {
      const relativePath = path.relative(cwd, file.getFilePath());
      console.log(relativePath);
    }
    console.error(`\nFound ${referencingFiles.length} file(s).`);
  }
}
