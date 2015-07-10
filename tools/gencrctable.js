var crctable = [];

for (var n = 0; n < 256; n++) {
	var c = n;
	for (var k = 0; k < 8; k++)
		c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
	crctable.push(c);
}

for (var i = 0; i < crctable.length; i++) {
	var value = crctable[i] + (crctable[i] < 0 ? 0x100000000 : 0);
	console.log("\tdd " + ("00000000" + value.toString(16).toUpperCase()).slice(-9) + "H");
}
