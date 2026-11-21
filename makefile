

run: boot
	./stsh prg/hello0.s hello0.txt
	cat hello0.txt

dis: preboot
	dd if=stsh0 of=tmp.bin bs=1 skip=120
	objdump -D -b binary -m i386:x86-64 tmp.bin -M intel
	-rm tmp.bin

preboot:
	@cut -d'#' -f1 stoneship.s | xxd -r -p > stsh0
	@chmod +x stsh0
boot: preboot
	@./stsh0 stoneship.s stsh1
	@diff stsh0 stsh1 \
		|| (echo "compiler invalid! no fixpoint! *the walls start melting*"; false) \
		&& (echo "compiler valid! *headpats compiler* good compiler~"      ; true )
	@mv stsh1 stsh
	@rm stsh0

