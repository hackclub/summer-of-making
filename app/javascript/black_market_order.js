document.addEventListener('DOMContentLoaded', function () {
    const quantityInput = document.querySelector('input[name="quantity"]');
    const quantityDisplay = document.getElementById('quantity-display');
    const totalCostContainer = document.getElementById('total-cost-container');
    const insufficientFundsWarning = document.getElementById('insufficient-funds-warning');
    const shortageAmount = document.getElementById('shortage-amount');
    const submitButton = document.getElementById('purchase-button');

    const itemPrice = parseInt(totalCostContainer.textContent.replace(/[^0-9]/g, ''));
    const userBalance = parseInt(document.querySelector('.balance-box .price-row span:last-child').textContent.replace(/[^0-9]/g, ''));

    function updateCostPreview() {
        const quantity = parseInt(quantityInput.value) || 1;
        const totalCost = itemPrice * quantity;
        const canAfford = userBalance >= totalCost;

        quantityDisplay.textContent = quantity;
        totalCostContainer.textContent = totalCost.toLocaleString() + ' 🐚';

        if (canAfford) {
            insufficientFundsWarning.classList.add('hidden');
            if (submitButton && !submitButton.dataset.initialDisabled) {
                submitButton.disabled = false;
                submitButton.value = 'Complete Purchase';
            }
        } else {
            insufficientFundsWarning.classList.remove('hidden');
            shortageAmount.textContent = (totalCost - userBalance).toLocaleString();
            if (submitButton) {
                submitButton.disabled = true;
                submitButton.value = 'Insufficient Shells';
            }
        }
    }

    if (quantityInput) {
        quantityInput.addEventListener('input', updateCostPreview);
        quantityInput.addEventListener('change', updateCostPreview);
        updateCostPreview();
    }
}); 