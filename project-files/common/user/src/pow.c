int multiply(int a, int b) {
	int product = 0;
	int mask = 1;
	for (int i = 0; i < 32; i++) {
		if (b & mask) {
			product += a;
		}
		a <<= 1;
		mask <<= 1;
	}
	return product;
}

__attribute__((noinline))
int pow(int a, int b) { // $t2, $s0
	int product = 1; // $s1
	while (b > 0) {
		if (b & 1) {
			product = multiply(product, a);
		}
		a = multiply(a, a);
		b >>= 1;
	}
	return product;
}

void main() {
    volatile int result = pow(3, 19);
}