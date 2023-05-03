describe('Octopub', () => {
    it('Should display header', () => {
    	cy.visit({url: '/', retryOnStatusCodeFailure: true})
        cy.get('#header').should('not.be.empty')
    })
})