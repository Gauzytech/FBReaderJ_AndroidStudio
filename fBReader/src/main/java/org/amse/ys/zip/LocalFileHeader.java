package org.amse.ys.zip;

/**
 * Class consists of constants, describing a compressed file. Contains only
 * construcor, all fields are final.
 */

import java.io.IOException;

/**
 * 记录了epub文件内部的xml文件具体从epub文件字节流哪个位置开始
 * 压缩状态下占据多少字节以及解压状态下占据多少字节
 */
public class LocalFileHeader {
	static final int FILE_HEADER_SIGNATURE = 0x04034b50;
	static final int FOLDER_HEADER_SIGNATURE = 0x02014b50;
	static final int END_OF_CENTRAL_DIRECTORY_SIGNATURE = 0x06054b50;
	static final int DATA_DESCRIPTOR_SIGNATURE = 0x08074b50;

	int Signature;

	int Version;
	int Flags;
	int CompressionMethod;
	int ModificationTime;
	int ModificationDate;
	int CRC32;
	// 这个属性记录了这个xml文件在压缩状态下在字节流中占据了多少字节
	int CompressedSize;
	// 这个属性记录了xml文件在解压状态下会占据多少字节
	int UncompressedSize;
	int NameLength;
	int ExtraLength;

	public String FileName;
	// 这个属性记录了epub内部xml文件代表了从字节流的哪个位置开始
	int DataOffset;

	LocalFileHeader() {
	}

	void readFrom(MyBufferedInputStream stream) throws IOException {
		Signature = stream.read4Bytes();
		switch (Signature) {
			default:
				break;
			case END_OF_CENTRAL_DIRECTORY_SIGNATURE:
			{
				stream.skip(16);
				int comment = stream.read2Bytes();
				stream.skip(comment);
				break;
			}
			case FOLDER_HEADER_SIGNATURE:
			{
				Version = stream.read4Bytes();
				Flags = stream.read2Bytes();
				CompressionMethod = stream.read2Bytes();
				ModificationTime = stream.read2Bytes();
				ModificationDate = stream.read2Bytes();
				CRC32 = stream.read4Bytes();
				CompressedSize = stream.read4Bytes();
				UncompressedSize = stream.read4Bytes();
				if (CompressionMethod == 0 && CompressedSize != UncompressedSize) {
					CompressedSize = UncompressedSize;
				}
				NameLength = stream.read2Bytes();
				ExtraLength = stream.read2Bytes();
				int comment = stream.read2Bytes();
				stream.skip(12);
				FileName = stream.readString(NameLength);
				stream.skip(ExtraLength);
				stream.skip(comment);
				break;
			}
			case FILE_HEADER_SIGNATURE:
				Version = stream.read2Bytes();
				Flags = stream.read2Bytes();
				CompressionMethod = stream.read2Bytes();
				ModificationTime = stream.read2Bytes();
				ModificationDate = stream.read2Bytes();
				CRC32 = stream.read4Bytes();
				CompressedSize = stream.read4Bytes();
				UncompressedSize = stream.read4Bytes();
				if (CompressionMethod == 0 && CompressedSize != UncompressedSize) {
					CompressedSize = UncompressedSize;
				}
				NameLength = stream.read2Bytes();
				ExtraLength = stream.read2Bytes();
				FileName = stream.readString(NameLength);
				stream.skip(ExtraLength);
				break;
			case DATA_DESCRIPTOR_SIGNATURE:
				CRC32 = stream.read4Bytes();
				CompressedSize = stream.read4Bytes();
				UncompressedSize = stream.read4Bytes();
				break;
		}
		DataOffset = stream.offset();
	}
}
