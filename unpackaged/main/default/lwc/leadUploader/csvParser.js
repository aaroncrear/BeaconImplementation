/**
 * Minimal RFC 4180 CSV parser: handles quoted fields, escaped quotes ("") and line breaks
 * inside quotes, CRLF/LF/CR line endings and a leading byte-order mark. Blank lines are dropped.
 * Returns an array of rows, each an array of strings.
 */
export function parseCsv(text) {
    let source = text || '';
    if (source.charCodeAt(0) === 0xfeff) {
        source = source.slice(1);
    }

    const rows = [];
    let row = [];
    let field = '';
    let inQuotes = false;

    for (let i = 0; i < source.length; i++) {
        const char = source[i];
        if (inQuotes) {
            if (char === '"') {
                if (source[i + 1] === '"') {
                    field += '"';
                    i++;
                } else {
                    inQuotes = false;
                }
            } else {
                field += char;
            }
        } else if (char === '"') {
            inQuotes = true;
        } else if (char === ',') {
            row.push(field);
            field = '';
        } else if (char === '\n' || char === '\r') {
            if (char === '\r' && source[i + 1] === '\n') {
                i++;
            }
            row.push(field);
            rows.push(row);
            row = [];
            field = '';
        } else {
            field += char;
        }
    }

    if (inQuotes) {
        throw new Error('The file has a quoted value that is never closed. Check for a stray " character.');
    }
    if (field !== '' || row.length > 0) {
        row.push(field);
        rows.push(row);
    }
    return rows.filter((r) => r.some((value) => value.trim() !== ''));
}

/** Turns an array of rows back into CSV text. */
export function toCsv(rows) {
    return rows.map((row) => row.map(escapeValue).join(',')).join('\r\n');
}

function escapeValue(value) {
    const text = value === null || value === undefined ? '' : String(value);
    return /[",\r\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

/** Lower-cases and strips everything but letters and digits, so "Zip/Postal Code" matches "zippostalcode". */
export function normalizeHeader(value) {
    return (value || '').toLowerCase().replace(/[^a-z0-9]/g, '');
}
