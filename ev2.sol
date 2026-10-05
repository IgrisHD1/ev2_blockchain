// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Cachipun {
    uint public montoApuesta;
    uint public finRevelacion;
    
    address payable public jugador1;
    address payable public jugador2;
    
    bytes32 public hashJugador1;
    bytes32 public hashJugador2;
    
    uint8 public jugadaJugador1;
    uint8 public jugadaJugador2;
    
    bool public reveladoJugador1;
    bool public reveladoJugador2;
    
    enum Estado { EsperandoJugadores, EsperandoRevelacion, Finalizado }
    Estado public estadoActual;

    constructor(uint _montoApuesta) {
        montoApuesta = _montoApuesta;
        estadoActual = Estado.EsperandoJugadores;
    }

    function jugar(bytes32 _hashJugada) public payable {
        require(estadoActual == Estado.EsperandoJugadores, "No se aceptan mas jugadores");
        require(msg.value == montoApuesta, "La apuesta debe ser exacta");
        require(jugador1 == address(0) || jugador2 == address(0), "El juego esta lleno");

        if (jugador1 == address(0)) {
            jugador1 = payable(msg.sender);
            hashJugador1 = _hashJugada;
        } else {
            require(msg.sender != jugador1, "No puedes jugar contra ti mismo");
            jugador2 = payable(msg.sender);
            hashJugador2 = _hashJugada;
            
            estadoActual = Estado.EsperandoRevelacion;
            finRevelacion = block.timestamp + 5 minutes;
        }
    }

    function revelar(uint8 _jugada, string memory _secreto) public {
        require(estadoActual == Estado.EsperandoRevelacion, "No es momento de revelar");
        require(_jugada >= 1 && _jugada <= 3, "Jugada invalida (1:Piedra, 2:Papel, 3:Tijera)");
        
        bytes32 hashCalculado = keccak256(abi.encodePacked(_jugada, _secreto));

        if (msg.sender == jugador1) {
            require(!reveladoJugador1, "Ya revelaste tu jugada");
            require(hashCalculado == hashJugador1, "El hash no coincide con tu apuesta");
            jugadaJugador1 = _jugada;
            reveladoJugador1 = true;
        } else if (msg.sender == jugador2) {
            require(!reveladoJugador2, "Ya revelaste tu jugada");
            require(hashCalculado == hashJugador2, "El hash no coincide con tu apuesta");
            jugadaJugador2 = _jugada;
            reveladoJugador2 = true;
        } else {
            revert("No eres parte de esta partida");
        }

        if (reveladoJugador1 && reveladoJugador2) {
            definirGanador();
        }
    }

    function definirGanador() internal {
        estadoActual = Estado.Finalizado;
        uint totalPozo = address(this).balance;

        if (jugadaJugador1 == jugadaJugador2) {
            (bool exito1, ) = jugador1.call{value: totalPozo / 2}("");
            require(exito1, "Fallo envio a jugador 1");
            (bool exito2, ) = jugador2.call{value: totalPozo / 2}("");
            require(exito2, "Fallo envio a jugador 2");
        } else if (
            (jugadaJugador1 == 1 && jugadaJugador2 == 3) ||
            (jugadaJugador1 == 2 && jugadaJugador2 == 1) ||
            (jugadaJugador1 == 3 && jugadaJugador2 == 2)
        ) {
            (bool exito, ) = jugador1.call{value: totalPozo}("");
            require(exito, "Fallo envio a jugador 1");
        } else {
            (bool exito, ) = jugador2.call{value: totalPozo}("");
            require(exito, "Fallo envio a jugador 2");
        }
    }

    function reclamarPorFaltaDeRevelacion() public {
        require(estadoActual == Estado.EsperandoRevelacion, "No aplica en esta fase");
        require(block.timestamp > finRevelacion, "Aun hay tiempo para revelar");

        estadoActual = Estado.Finalizado;
        uint totalPozo = address(this).balance;

        if (!reveladoJugador1 && !reveladoJugador2) {
            (bool exito1, ) = jugador1.call{value: totalPozo / 2}("");
            require(exito1, "Fallo envio a jugador 1");
            (bool exito2, ) = jugador2.call{value: totalPozo / 2}("");
            require(exito2, "Fallo envio a jugador 2");
        } else if (reveladoJugador1 && !reveladoJugador2) {
            (bool exito, ) = jugador1.call{value: totalPozo}("");
            require(exito, "Fallo envio a jugador 1");
        } else if (!reveladoJugador1 && reveladoJugador2) {
            (bool exito, ) = jugador2.call{value: totalPozo}("");
            require(exito, "Fallo envio a jugador 2");
        }
    }
}