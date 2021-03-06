/*
 * format - haXe File Formats
 *
 * Copyright (c) 2008, The haXe Project Contributors
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package format.flv;
import format.flv.Data;

class Reader {

	var ch : haxe.io.Input;

	public function new( i ) {
		this.ch = i;
		i.bigEndian = true;
	}

	public function close() {
		ch.close();
	}

	public function readHeader() : Header {
		if( ch.readString(3) != 'FLV' )
			throw "Invalid signature";
		if( ch.readByte() != 0x01 )
			throw "Invalid version";
		var flags = ch.readByte();
		if( flags & 0xF2 != 0 )
			throw "Invalid type flags "+flags;
		var offset = ch.readUInt30();
		if( offset != 0x09 )
			throw "Invalid offset "+offset;
		var prev = ch.readUInt30();
		if( prev != 0 )
			throw "Invalid prev "+prev;
		return {
			hasAudio : (flags & 1) != 0,
			hasVideo : (flags & 4) != 0,
			hasMeta : (flags & 8) != 0,
		};
	}

	public function readChunk() : Null<Data> {
		var k;
		try
			k = ch.readByte()
		catch( e : haxe.io.Eof )
			return null;
		var size = ch.readUInt24();
		var time = ch.readUInt24();
		var reserved = ch.readUInt30();
		if( reserved != 0 )
			throw "Invalid reserved "+reserved;
		var data = ch.read(size);
		var size2 = ch.readUInt30();
		if( size2 != 0 && size2 != size + 11 )
			throw "Invalid size2 ("+size+" != "+size2+")";
		return switch( k ) {
		case 0x08:
			FLVAudio(data,time);
		case 0x09:
			FLVVideo(data,time);
		case 0x12:
			FLVMeta(data,time);
		default:
			throw "Invalid FLV tag "+k;
		}
	}

}