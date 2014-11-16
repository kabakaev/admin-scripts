#Time machine backup disk in an image file

1. Create your Disk Image: App/Utilities/Disk utility

2. Mount the disk image

3. From the command line, enter the following:
	sudo tmutil setdestination /Volumes/{mounted-image-name}

4. Start Time Machine manually within the menu bar via "Back Up Now"

Based on http://apple.stackexchange.com/questions/95148/how-can-i-make-my-computer-believe-a-disk-image-is-a-hardware-disk
