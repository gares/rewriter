static void feadd(uint64_t out[7], const uint64_t in1[7], const uint64_t in2[7]) {
  { const uint64_t x14 = in1[6];
  { const uint64_t x15 = in1[5];
  { const uint64_t x13 = in1[4];
  { const uint64_t x11 = in1[3];
  { const uint64_t x9 = in1[2];
  { const uint64_t x7 = in1[1];
  { const uint64_t x5 = in1[0];
  { const uint64_t x26 = in2[6];
  { const uint64_t x27 = in2[5];
  { const uint64_t x25 = in2[4];
  { const uint64_t x23 = in2[3];
  { const uint64_t x21 = in2[2];
  { const uint64_t x19 = in2[1];
  { const uint64_t x17 = in2[0];
  { uint64_t x29; uint8_t x30 = _addcarryx_u64(0x0, x5, x17, &x29);
  { uint64_t x32; uint8_t x33 = _addcarryx_u64(x30, x7, x19, &x32);
  { uint64_t x35; uint8_t x36 = _addcarryx_u64(x33, x9, x21, &x35);
  { uint64_t x38; uint8_t x39 = _addcarryx_u64(x36, x11, x23, &x38);
  { uint64_t x41; uint8_t x42 = _addcarryx_u64(x39, x13, x25, &x41);
  { uint64_t x44; uint8_t x45 = _addcarryx_u64(x42, x15, x27, &x44);
  { uint64_t x47; uint8_t x48 = _addcarryx_u64(x45, x14, x26, &x47);
  { uint64_t x50; uint8_t x51 = _subborrow_u64(0x0, x29, 0xffffffffffffffffL, &x50);
  { uint64_t x53; uint8_t x54 = _subborrow_u64(x51, x32, 0xffffffffffffffffL, &x53);
  { uint64_t x56; uint8_t x57 = _subborrow_u64(x54, x35, 0xffffffffffffffffL, &x56);
  { uint64_t x59; uint8_t x60 = _subborrow_u64(x57, x38, 0xfffffffeffffffffL, &x59);
  { uint64_t x62; uint8_t x63 = _subborrow_u64(x60, x41, 0xffffffffffffffffL, &x62);
  { uint64_t x65; uint8_t x66 = _subborrow_u64(x63, x44, 0xffffffffffffffffL, &x65);
  { uint64_t x68; uint8_t x69 = _subborrow_u64(x66, x47, 0xffffffffffffffffL, &x68);
  { uint64_t _; uint8_t x72 = _subborrow_u64(x69, x48, 0x0, &_);
  { uint64_t x73 = cmovznz64(x72, x68, x47);
  { uint64_t x74 = cmovznz64(x72, x65, x44);
  { uint64_t x75 = cmovznz64(x72, x62, x41);
  { uint64_t x76 = cmovznz64(x72, x59, x38);
  { uint64_t x77 = cmovznz64(x72, x56, x35);
  { uint64_t x78 = cmovznz64(x72, x53, x32);
  { uint64_t x79 = cmovznz64(x72, x50, x29);
  out[0] = x79;
  out[1] = x78;
  out[2] = x77;
  out[3] = x76;
  out[4] = x75;
  out[5] = x74;
  out[6] = x73;
  }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
}
