import * as fs from 'fs';
import * as path from 'path';

const backendRoot = path.resolve(__dirname, '../..');

function readDirectoryText(directoryPath: string): string {
    return fs
        .readdirSync(directoryPath, { withFileTypes: true })
        .flatMap(entry => {
            const childPath = path.join(directoryPath, entry.name);
            if (entry.isDirectory()) {
                return readDirectoryText(childPath);
            }
            if (!entry.isFile() || !/\.(ts|prisma|json)$/.test(entry.name)) {
                return [];
            }
            return fs.readFileSync(childPath, 'utf8');
        })
        .join('\n');
}

export function readBackendFile(relativePath: string): string {
    const targetPath = path.join(backendRoot, relativePath);
    const stats = fs.statSync(targetPath);
    if (stats.isDirectory()) {
        return readDirectoryText(targetPath);
    }
    return fs.readFileSync(targetPath, 'utf8');
}

export function expectFileContains(relativePath: string, snippets: string[]): string {
    const content = readBackendFile(relativePath);
    for (const snippet of snippets) {
        expect(content).toContain(snippet);
    }
    return content;
}

export function expectFileOmits(relativePath: string, snippets: string[]): string {
    const content = readBackendFile(relativePath);
    for (const snippet of snippets) {
        expect(content).not.toContain(snippet);
    }
    return content;
}
