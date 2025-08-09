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
void main() {
    volatile int result = multiply(3, 9);
}