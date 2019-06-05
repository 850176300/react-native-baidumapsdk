import React, { Component } from 'react'
import { StyleSheet } from 'react-native'
import { MapView } from 'react-native-bmpsdk'

export default class Basic extends Component {
  static navigationOptions = { title: 'Basic usage' }

  render() {
    return <MapView style={StyleSheet.absoluteFill} />
  }
}
