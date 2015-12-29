-- send.lua
--local x
local RADIO_READ  = 0x80
local RADIO_WRITE = 0x00
local RADIO_BURST = 0x40

local config = {
    [0x15] = 0x35, -- RADIO_REG_DEVIATN
    [0x09] = 0x00, -- RADIO_REG_ADDR
    [0x1d] = 0x91, --RADIO_REG_AGCCTRL0
    [0x1c] = 0x40, -- RADIO_REG_AGCCTRL1
    [0x1b] = 0x03, -- RADIO_REG_AGCCTRL2
    [0x1a] = 0x6E, -- RADIO_REG_BSCFG
    [0x0a] = 0x00, -- RADIO_REG_CHANNR
}

--[[    
    [] = 0x03, -- RADIO_REG_FIFOTHR
    [] = 0x16, -- RADIO_REG_FOCCFG
    [] = 0x10, -- RADIO_REG_FREND0
    [] = 0x56, -- RADIO_REG_FREND1
    [] = 0x1F, -- RADIO_REG_FSCAL0
    [] = 0x00, -- RADIO_REG_FSCAL1
    [] = 0x2A, -- RADIO_REG_FSCAL2
    [] = 0xE9, -- RADIO_REG_FSCAL3
    [] = 0x00, -- RADIO_REG_FSCTRL0
    [] = 0x06, -- RADIO_REG_FSCTRL1
    [] = 0x59, -- RADIO_REG_FSTEST
    [] = 0x04, -- RADIO_REG_IOCFG0 // 0x08 interrupt od det sync slova , 0x04 do verflow rx
    [] = 0x08, -- RADIO_REG_IOCFG2
    [] = 0x14, -- RADIO_REG_MCSM0
    [] = 0x0F, -- RADIO_REG_MCSM1
    [] = 0xF8, -- RADIO_REG_MDMCFG0
    [] = 0x17, -- RADIO_REG_MDMCFG2 // ok  0x17(30/32 sync) 0x16 (16/16 sync)
    [] = 0x83, -- RADIO_REG_MDMCFG3
    [] = 0xBA, -- RADIO_REG_MDMCFG4
    [] = 0xC0, -- RADIO_REG_PATABLE
    [] = LENGTH_CONFIG_VARIABLE, -- RADIO_REG_PKTCTRL0 
    [] = (2 << PQT_OFFSET) | APPEND_STATUS, -- RADIO_REG_PKTCTRL1
    [] = 0xFF, -- RADIO_REG_PKTLEN
    [] = 0x91, -- RADIO_REG_SYNC0
    [] = 0xCC, -- RADIO_REG_SYNC1
    [] = 0x09, -- RADIO_REG_TEST0
    [] = 0x35, -- RADIO_REG_TEST1
    [] = 0x81, -- RADIO_REG_TEST2
    [] = 0x00, -- RADIO_REG_INVALID
}; 
]]--

local function RadioInitSPI()
    spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, spi.DATABITS_8, 16, spi.HALFDUPLEX)
end

local function RadioConfigure()

    -- resetovani radia
    spi.send(1,0x30) -- RADIO_CMD_SRES

    tmr.delay(1000*1000)
    
    spi.send(1,0x36) -- RADIO_CMD_SIDLE
    
    tmr.delay(100*1000) -- je lepsi tu nechat chvilku delay, at se opravdu prepne

    local freq = 0x216372
    spi.send(BIT.BOR(0x0d,RADIO_WRITE), BIT.LSHIFT(freq,16)) -- RADIO_REG_FREQ2
    spi.send(BIT.BOR(0x0e,RADIO_WRITE), BIT.LSHIFT(freq,8)) -- RADIO_REG_FREQ1 predpokladam ze to posle jen dolnich 8 bitu
    spi.send(BIT.BOR(0x0f,RADIO_WRITE), BIT.LSHIFT(freq)) -- RADIO_REG_FREQ0 predpokladam ze to posle jen dolnich 8 bitu

--[[
    radio_xApplyConfig(...config) = 
    while (pConfig->address != RADIO_REG_INVALID) {
        radio_spi_xwrite(pConfig->address, pConfig->value);
        pConfig++;
    } 

    radio_spi_ccmd(SRX);
    Task_Sleep_ms_Self(1);

    radio_spi_ccmd(SIDLE);
    Task_Sleep_ms_Self(1);

    radio_spi_ccmd(STX);
    Task_Sleep_ms_Self(1);

    radio_spi_ccmd(SIDLE);
    Task_Sleep_ms_Self(1);

    radio_spi_ccmd(SFRX);
    radio_spi_ccmd(SFTX);
    radio_spi_ccmd(SCAL);

    spi_free();
    spi_post();
}
]]--
end







--[[    #define radio_spi_ccmd(cmd)  \
        radio_spi_xcmd(RADIO_CMD_##cmd)
    ve skutecnosti SPI send

void radio_spi_xwrite(unsigned char addr, unsigned char data)
    /* pridam priznak zapisu */
    addr |= RADIO_WRITE;

    /* poslu adresu a data */
    spi_transmit(addr);
    spi_transmit(data);
} 


/**
 * @ingroup   radio
 * @file      radio_reg_cc1101.h
 * @brief     Mapa registru radioveho transcieveru CC1101.
 * @author    Jiri Vit
 */

/*
 * Transciever ma dva druhy registru: konfiguracni a stavove.
 * KONFIGURACNI registry jsou na adresach 0x00-0x2f, lze je cist i zapisovat a
 * lze pouzivat 'burst' mod, tedy zapis/cteni vice po sobe jdoucich registru.
 * STAVOVE registry jsou na adresach 0x30-0x3d a lze je pouze cist. Pri cteni
 * musi byt nastaven bit BURST, protoze na tech samych adresach jsou i prikazy
 * a prave podle burstu transciever pozna, ze chceme pouzivat stavove registry.
 * PRIKAZY nejsou urcene k vymene dat, ale pouze k predavani pokynu pro
 * transciever. Sdileji adresy se stavovymi registry. Prikaz se zavola odeslanim
 * jeho adresy, kde ovsem nesmi byt BURST bit.
 */


#ifndef _RADIO_REG_CC1101_H_INCLUDED
#define _RADIO_REG_CC1101_H_INCLUDED

/* R/W configuration registers, burst access possible */
#define RADIO_REG_IOCFG2           0x00
#define RADIO_REG_IOCFG1           0x01
#define RADIO_REG_IOCFG0           0x02
#define RADIO_REG_FIFOTHR          0x03
#define RADIO_REG_SYNC1            0x04
#define RADIO_REG_SYNC0            0x05
#define RADIO_REG_PKTLEN           0x06
#define RADIO_REG_PKTCTRL1         0x07
#define RADIO_REG_PKTCTRL0         0x08
#define RADIO_REG_ADDR             0x09
#define RADIO_REG_CHANNR           0x0a
#define RADIO_REG_FSCTRL1          0x0b
#define RADIO_REG_FSCTRL0          0x0c
#define RADIO_REG_FREQ2            0x0d
#define RADIO_REG_FREQ1            0x0e
#define RADIO_REG_FREQ0            0x0f
#define RADIO_REG_MDMCFG4          0x10
#define RADIO_REG_MDMCFG3          0x11
#define RADIO_REG_MDMCFG2          0x12
#define RADIO_REG_MDMCFG1          0x13
#define RADIO_REG_MDMCFG0          0x14
#define RADIO_REG_DEVIATN          0x15
#define RADIO_REG_MCSM2            0x16
#define RADIO_REG_MCSM1            0x17
#define RADIO_REG_MCSM0            0x18
#define RADIO_REG_FOCCFG           0x19
#define RADIO_REG_BSCFG            0x1a
#define RADIO_REG_AGCCTRL2         0x1b
#define RADIO_REG_AGCCTRL1         0x1c
#define RADIO_REG_AGCCTRL0         0x1d
#define RADIO_REG_WOREVT1          0x1e
#define RADIO_REG_WOREVT0          0x1f
#define RADIO_REG_WORCTRL          0x20
#define RADIO_REG_FREND1           0x21
#define RADIO_REG_FREND0           0x22
#define RADIO_REG_FSCAL3           0x23
#define RADIO_REG_FSCAL2           0x24
#define RADIO_REG_FSCAL1           0x25
#define RADIO_REG_FSCAL0           0x26
#define RADIO_REG_RCCTRL1          0x27
#define RADIO_REG_RCCTRL0          0x28
#define RADIO_REG_FSTEST           0x29
#define RADIO_REG_PTEST            0x2a
#define RADIO_REG_AGCTEST          0x2b
#define RADIO_REG_TEST2            0x2c
#define RADIO_REG_TEST1            0x2d
#define RADIO_REG_TEST0            0x2e

/* Command strobes (no burst bit) */
#define RADIO_CMD_SRES             0x30
#define RADIO_CMD_SFSTXON          0x31
#define RADIO_CMD_SXOFF            0x32
#define RADIO_CMD_SCAL             0x33
#define RADIO_CMD_SRX              0x34
#define RADIO_CMD_STX              0x35
#define RADIO_CMD_SIDLE            0x36
#define RADIO_CMD_SWOR             0x38
#define RADIO_CMD_SPWD             0x39
#define RADIO_CMD_SFRX             0x3a
#define RADIO_CMD_SFTX             0x3b
#define RADIO_CMD_SWORRST          0x3c
#define RADIO_CMD_SNOP             0x3d

/* Status registers (read only, burst bit) */
#define RADIO_REG_PARTNUM          0x30
#define RADIO_REG_VERSION          0x31
#define RADIO_REG_FREQEST          0x32
#define RADIO_REG_LQI              0x33
#define RADIO_REG_RSSI             0x34
#define RADIO_REG_MARCSTATE        0x35
#define RADIO_REG_WORTIME1         0x36
#define RADIO_REG_WORTIME0         0x37
#define RADIO_REG_PKTSTATUS        0x38
#define RADIO_REG_VCO_VC_DAC       0x39
#define RADIO_REG_TXBYTES          0x3a
#define RADIO_REG_RXBYTES          0x3b
#define RADIO_REG_RCCTRL1_STATUS   0x3c
#define RADIO_REG_RCCTRL0_STATUS   0x3d

/* PATABLE */
#define RADIO_REG_PATABLE          0x3e

/* FIFO */
#define RADIO_REG_FIFO             0x3f

/* internal */
#define RADIO_REG_INVALID          0xff


/* Chip Status Byte */
#define RADIO_STATE_MASK                 (0x07 << 4)
#define RADIO_STATE_IDLE                 (0x00 << 4)
#define RADIO_STATE_RX                   (0x01 << 4)
#define RADIO_STATE_TX                   (0x02 << 4)
#define RADIO_STATE_FSTXON               (0x03 << 4)
#define RADIO_STATE_CALIBRATE            (0x04 << 4)
#define RADIO_STATE_SETTLING             (0x05 << 4)
#define RADIO_STATE_RXFIFO_OVERFLOW      (0x06 << 4)
#define RADIO_STATE_TXFIFO_UNDERFLOW     (0x07 << 4)
#define RADIO_FIFO_BYTES_AVAILABLE_MASK   0x0f


/* PKTCTRL1 - Packet Automation Control */
#define PQT_OFFSET  5
#define CRC_AUTOFLUSH 0x08
#define APPEND_STATUS 0x04

#define LENGTH_CONFIG_FIXED     0x00
#define LENGTH_CONFIG_VARIABLE  0x01
#define LENGTH_CONFIG_INFINITE  0x02

#define SYNC_MODE_NOSYNC 0x00
#define SYNC_MODE_30_32  0x03

#endif /* _RADIO_REG_CC1101_H_INCLUDED */ 


]] --
        
local function KontrolaPrijmu()
    -- vycti buffer
    -- desifruj
    -- kdyz neco nastav data pro prenos na cloud

    -- nacasuj dalsi kontrolu    
    if Debug_S == 1 then
        tmr.alarm(TM["r"], 3000, 0,  function() KontrolaPrijmu() end)
    else
        tmr.alarm(TM["r"], 100, 0,  function() KontrolaPrijmu() end)
    end
end

-- inicializuji SPI
RadioInitSPI()
-- nakonfiguruju radio
RadioConfigure()
-- aktivuji desifrovaci knihovny
-- x = require("")

-- spust prijem
KontrolaPrijmu()

