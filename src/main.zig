const std = @import("std");
const mem = std.mem;
const testing = std.testing;

fn fmix64(v: u64) u64 {
    var k = v;
    k ^= k >> 33;
    k *%= 0xff51afd7ed558ccd;
    k ^= k >> 33;
    k *%= 0xc4ceb9fe1a85ec53;
    k ^= k >> 33;
    return k;
}

fn rotate_left(x: u64, r: u8) u64 {
    const r1 = @truncate(u6, r);
    const r2 = @truncate(u6, 64 - r);
    return (x << r1) | (x >> r2);
}

fn get_128_block(bytes: []const u8, index: usize) [2]u64 {
    const ptr = std.mem.bytesAsSlice(u64, bytes);
    return [_]u64{ ptr[index], ptr[index + 1] };
}

fn murmurhash3_x64_128(bytes: []const u8, seed: u64) [2]u64 {
    const c1: u64 = 0x87c37b91114253d5;
    const c2: u64 = 0x4cf5ad432745937f;
    const read_size = 16;
    const len: u64 = bytes.len;
    const block_count = len / read_size;
    var v = [_]u64{ seed, seed };
    var index: usize = 0;

    while (index < block_count) : (index += 1) {
        const kk = get_128_block(bytes, index * 2);
        var k1 = kk[0];
        var k2 = kk[1];

        k1 *%= c1;
        k1 = rotate_left(k1, 31);
        k1 *%= c2;
        v[0] ^= k1;

        v[0] = rotate_left(v[0], 27);
        v[0] +%= v[1];
        v[0] *%= 5;
        v[0] +%= 0x52dce729;

        k2 *%= c2;
        k2 = rotate_left(k2, 33);
        k2 *%= c1;
        v[1] ^= k2;

        v[1] = rotate_left(v[1], 31);
        v[1] +%= v[0];
        v[1] *%= 5;
        v[1] +%= 0x38495ab5;
    }

    var k = [_]u64{ 0, 0 };

    if (len & 15 == 15) {
        k[1] ^= (@as(u64, bytes[(block_count * read_size) + 14])) << 48;
    }
    if (len & 15 >= 14) {
        k[1] ^= (@as(u64, bytes[(block_count * read_size) + 13])) << 40;
    }
    if (len & 15 >= 13) {
        k[1] ^= (@as(u64, bytes[(block_count * read_size) + 12])) << 32;
    }
    if (len & 15 >= 12) {
        k[1] ^= (@as(u64, bytes[(block_count * read_size) + 11])) << 24;
    }
    if (len & 15 >= 11) {
        k[1] ^= (@as(u64, bytes[(block_count * read_size) + 10])) << 16;
    }
    if (len & 15 >= 10) {
        k[1] ^= (@as(u64, bytes[(block_count * read_size) + 9])) << 8;
    }
    if (len & 15 >= 9) {
        k[1] ^= @as(u64, bytes[(block_count * read_size) + 8]);
        k[1] *%= c2;
        k[1] = rotate_left(k[1], 33);
        k[1] *%= c1;
        v[1] ^= k[1];
    }

    if (len & 15 >= 8) {
        k[0] ^= (@as(u64, bytes[(block_count * read_size) + 7])) << 56;
    }
    if (len & 15 >= 7) {
        k[0] ^= (@as(u64, bytes[(block_count * read_size) + 6])) << 48;
    }
    if (len & 15 >= 6) {
        k[0] ^= (@as(u64, bytes[(block_count * read_size) + 5])) << 40;
    }
    if (len & 15 >= 5) {
        k[0] ^= (@as(u64, bytes[(block_count * read_size) + 4])) << 32;
    }
    if (len & 15 >= 4) {
        k[0] ^= (@as(u64, bytes[(block_count * read_size) + 3])) << 24;
    }
    if (len & 15 >= 3) {
        k[0] ^= (@as(u64, bytes[(block_count * read_size) + 2])) << 16;
    }
    if (len & 15 >= 2) {
        k[0] ^= (@as(u64, bytes[(block_count * read_size) + 1])) << 8;
    }
    if (len & 15 >= 1) {
        k[0] ^= @as(u64, bytes[(block_count * read_size) + 0]);
        k[0] *%= c1;
        k[0] = rotate_left(k[0], 31);
        k[0] *%= c2;
        v[0] ^= k[0];
    }

    v[0] ^= len;
    v[1] ^= len;

    v[0] +%= v[1];
    v[1] +%= v[0];

    v[0] = fmix64(v[0]);
    v[1] = fmix64(v[1]);

    v[0] +%= v[1];
    v[1] +%= v[0];

    return v;
}

test "test tail lengths" {
    try testing.expect(mem.eql(u64, &murmurhash3_x64_128("", 0), &[_]u64{ 0, 0 }));
    try testing.expect(mem.eql(u64, &murmurhash3_x64_128("1", 0), &[_]u64{ 8213365047359667313, 10676604921780958775 }));
    try testing.expect(mem.eql(u64, &murmurhash3_x64_128("12", 0), &[_]u64{ 5355690773644049813, 9855895140584599837 }));
    try testing.expect(mem.eql(u64, &murmurhash3_x64_128("123", 0), &[_]u64{ 10978418110857903978, 4791445053355511657 }));
    try testing.expect(mem.eql(u64, &murmurhash3_x64_128("1234", 0), &[_]u64{ 619023178690193332, 3755592904005385637 }));
    try testing.expect(mem.eql(u64, &murmurhash3_x64_128("12345", 0), &[_]u64{ 2375712675693977547, 17382870096830835188 }));
    try testing.expect(mem.eql(u64, &murmurhash3_x64_128("123456", 0), &[_]u64{ 16435832985690558678, 5882968373513761278 }));
    try testing.expect(mem.eql(u64, &murmurhash3_x64_128("1234567", 0), &[_]u64{ 3232113351312417698, 4025181827808483669 }));
    try testing.expect(mem.eql(u64, &murmurhash3_x64_128("12345678", 0), &[_]u64{ 4272337174398058908, 10464973996478965079 }));
    try testing.expect(mem.eql(u64, &murmurhash3_x64_128("123456789", 0), &[_]u64{ 4360720697772133540, 11094893415607738629 }));
    try testing.expect(mem.eql(u64, &murmurhash3_x64_128("123456789a", 0), &[_]u64{ 12594836289594257748, 2662019112679848245 }));
    try testing.expect(mem.eql(u64, &murmurhash3_x64_128("123456789ab", 0), &[_]u64{ 6978636991469537545, 12243090730442643750 }));
    try testing.expect(mem.eql(u64, &murmurhash3_x64_128("123456789abc", 0), &[_]u64{ 211890993682310078, 16480638721813329343 }));
    try testing.expect(mem.eql(u64, &murmurhash3_x64_128("123456789abcd", 0), &[_]u64{ 12459781455342427559, 3193214493011213179 }));
    try testing.expect(mem.eql(u64, &murmurhash3_x64_128("123456789abcde", 0), &[_]u64{ 12538342858731408721, 9820739847336455216 }));
    try testing.expect(mem.eql(u64, &murmurhash3_x64_128("123456789abcdef", 0), &[_]u64{ 9165946068217512774, 2451472574052603025 }));
    try testing.expect(mem.eql(u64, &murmurhash3_x64_128("123456789abcdef1", 0), &[_]u64{ 9259082041050667785, 12459473952842597282 }));
}
